# Openshift-Data-Loader
FastAPI service that exposes data from a MySQL database (running as a separate pod on OpenShift).

## פיתוח מקומי
1. צור קובץ משתני סביבה (אופציונלי) או ייצא ידנית:
```
set DB_HOST=localhost
set DB_PORT=3306
set DB_USER=dbuser
set DB_PASSWORD=dbpass
set DB_NAME=dataloader
```
2. התקנת חבילות:
```
pip install -r requirements.txt
```
3. הרצה:
```
python -m uvicorn Services.main:app --reload --port 8000
```
4. בדיקת בריאות: http://localhost:8000/health

## בניית דוקר
```
docker build -t dataloader:latest .
docker run -e DB_HOST=mysql -e DB_USER=dbuser -e DB_PASSWORD=dbpass -e DB_NAME=dataloader -p 8000:8000 dataloader:latest
```

## OpenShift
צור אובייקטים למסד הנתונים:
```
oc apply -f Infrastructure/secret-db-credentials.yaml
oc apply -f Infrastructure/pvc-template.yaml
oc apply -f Infrastructure/deployment-app.yaml
oc apply -f Infrastructure/service-app.yaml
```

בנה את האפליקציה (דוקר סטרטג'י):
```
oc new-build --name=dataloader --binary --strategy=docker
oc start-build dataloader --from-dir=. --follow
```

פריסה:
```
oc new-app dataloader:latest --name=dataloader-app \
	-e DB_HOST=mysql -e DB_PORT=3306 -e DB_USER=dbuser -e DB_PASSWORD=dbpass -e DB_NAME=dataloader
oc expose svc/dataloader-app
```

בדיקת כתובת:
```
oc get route
```

בדיקת בריאות:
```
curl https://<route>/health
```

## הערות
- הטבלה `data` תיווצר ותתמלא ע"י סקריפט משלך; הסקריפט המצורף `Scripts/create_data.sql` כתוב ל-SQL Server (פקודת IF NOT EXISTS עם sysobjects). עבור MySQL השתמש:
```
CREATE TABLE IF NOT EXISTS data (
	ID INT PRIMARY KEY,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL
);
INSERT INTO data (ID, first_name, last_name) VALUES (1,'Ada','Lovelace') ON DUPLICATE KEY UPDATE first_name=VALUES(first_name), last_name=VALUES(last_name);
```

