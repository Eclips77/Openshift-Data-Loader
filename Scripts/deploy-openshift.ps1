<#
OpenShift deploy script.
Actions:
 1. Validate namespace (must already exist)
 2. Apply MySQL (Secret, PVC, Deployment, Service)
 3. Wait for MySQL ready
 4. Seed demo data (unless -SkipDBSeed)
 5. Ensure ImageStream+BuildConfig and binary build (unless -SkipBuild)
 6. Apply API (Deployment, Service, Route)
 7. Health check
#>

param(
    [string]$Namespace = 'lkey09211-dev',
    [switch]$SkipBuild,
    [switch]$SkipDBSeed,
    [switch]$ForceRebuild
)

$ErrorActionPreference = 'Stop'

# --- Helper log functions ---
function WStep($m){ Write-Host "[STEP] $m" -ForegroundColor Cyan }
function WInfo($m){ Write-Host "[INFO] $m" -ForegroundColor DarkGray }
function WOk($m){ Write-Host "[OK]   $m" -ForegroundColor Green }
function WWarn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function WErr($m){ Write-Host "[ERR]  $m" -ForegroundColor Red }

# --- Ensure oc exists ---
if(-not (Get-Command oc -ErrorAction SilentlyContinue)){ throw "oc not found" }

# --- Namespace validation ---
WStep "Namespace: $Namespace"
try { oc project $Namespace | Out-Null; WOk "Using namespace $Namespace" }
catch { WErr "Cannot access namespace $Namespace"; exit 1 }

# --- MySQL resources ---
$infraDir = Join-Path (Join-Path $PSScriptRoot '..') 'Infrastructure'
WStep 'Apply MySQL resources'
$dbFiles = 'secret-db-credentials.yaml','pvc-template.yaml','deployment-app.yaml','service-app.yaml'
foreach($f in $dbFiles){
    $p = Join-Path $infraDir $f
    if(Test-Path $p){
        oc apply -f $p | Out-Null
        WInfo "Applied ${f}"
    } else { throw "Missing ${f}" }
}

# --- Deployment waiter ---
function WaitDeploy([string]$name,[int]$timeoutSec=180){
    WInfo "Wait deployment/${name} up to ${timeoutSec} s"
    try {
        oc rollout status deployment/${name} --timeout=${timeoutSec}s | Out-Null
        WOk "deployment/${name} ready"
        return
    } catch { WWarn 'rollout status fallback to polling' }

    $start = Get-Date
    while((Get-Date)-$start -lt [TimeSpan]::FromSeconds($timeoutSec)){
        $avail = oc get deploy $name -o "jsonpath={.status.availableReplicas}" 2>$null
        if($LASTEXITCODE -eq 0 -and $avail -match '^[1-9]'){
            WOk "deployment/${name} available (${avail})"
            return
        }
        Start-Sleep 5
    }
    throw "Timeout waiting for deployment ${name}"
}

WStep 'Wait MySQL'
WaitDeploy mysql

# --- DB Seed ---
if(-not $SkipDBSeed){
    WStep 'Seed DB'
    $mysqlPod = oc get pod -l app=mysql -o "jsonpath={.items[0].metadata.name}" 2>$null
    if($mysqlPod){
        $seedSql = "CREATE TABLE IF NOT EXISTS data (ID INT PRIMARY KEY, first_name VARCHAR(50) NOT NULL, last_name VARCHAR(50) NOT NULL); INSERT INTO data (ID, first_name, last_name) VALUES (1,'Ada','Lovelace'),(2,'Alan','Turing'),(3,'Grace','Hopper'),(4,'Edsger','Dijkstra'),(5,'Donald','Knuth') ON DUPLICATE KEY UPDATE first_name=VALUES(first_name), last_name=VALUES(last_name);"
        try {
            $seedCmd = "mysql -u`$MYSQL_USER -p`$MYSQL_PASSWORD `$MYSQL_DATABASE -e `"$seedSql`""
            oc rsh $mysqlPod -- sh -c "$seedCmd" | Out-Null
            WOk 'Seed done'
        } catch { WWarn "Seed failed: $($_.Exception.Message)" }
    } else { WWarn 'MySQL pod not found - skip seed' }
} else { WWarn 'Skip DB seed' }

# --- Build ---
if(-not $SkipBuild){
    WStep 'Image build phase'
    $bc = Join-Path $infraDir 'imagestream-build.yaml'
    if(Test-Path $bc){
        oc apply -f $bc | Out-Null
        WInfo 'Applied imagestream-build.yaml'
    } else { throw 'Missing imagestream-build.yaml' }

    $need = $true
    if(-not $ForceRebuild){
        if(oc get istag dataloader:latest -o name 2>$null){
            WInfo 'Image exists (use -ForceRebuild to rebuild)'
            $need = $false
        }
    }
    if($need){
        WStep 'Start binary build'
        $rootDir = (Get-Item (Join-Path $PSScriptRoot '..')).FullName
        oc start-build dataloader --from-dir=$rootDir --follow | Out-Null
        WOk 'Build complete'
    }
} else { WWarn 'Skip build' }

# --- API manifests ---
WStep 'Apply API manifests'
$apiFiles = 'deployment-api.yaml','service-api.yaml','route-api.yaml'
foreach($f in $apiFiles){
    $p = Join-Path $infraDir $f
    if(Test-Path $p){
        try {
            oc apply -f $p | Out-Null
            WInfo "Applied ${f}"
        } catch {
            $msg = $_.Exception.Message
            WErr "Failed ${f}: ${msg}"
            exit 1
        }
    } else {
        WErr "Missing ${f}"
        exit 1
    }
}

try { WaitDeploy dataloader-api } catch { WErr $_; exit 1 }

# --- Health check ---
WStep 'Health check'
$routeHost = oc get route dataloader-api -o "jsonpath={.spec.host}" 2>$null
if($routeHost){
    $https = "https://${routeHost}/health"
    $http = "http://${routeHost}/health"
    try {
        $r = Invoke-RestMethod -Uri $https -Method GET -SkipCertificateCheck -TimeoutSec 15
        WOk "Health HTTPS: $($r.status)"
    }
    catch {
        WWarn 'HTTPS failed -> HTTP'
        try {
            $r2 = Invoke-RestMethod -Uri $http -Method GET -TimeoutSec 10
            WOk "Health HTTP: $($r2.status)"
        } catch { WWarn 'Health failed' }
    }
    WInfo "Route: https://${routeHost}"
} else { WWarn 'Route not found' }

WOk "Done. App and DB deployed in namespace ${Namespace}"
exit 0
