from mysql.connector.pooling import MySQLConnectionPool
from typing import List, Optional, Dict, Any
from Services.config import settings

class DataLoaderDAL:
    def _init_(self) -> None:
        self.pool = MySQLConnectionPool(
            pool_name=settings.POOL_NAME,
            pool_size=settings.POOL_SIZE,
            host=settings.DB_HOST,
            port=settings.DB_PORT,
            user=settings.DB_USER,
            password=settings.DB_PASSWORD,
            database=settings.DB_NAME,
            charset="utf8mb4",
            autocommit=True
        )

    def fetch_all(self) -> List[Dict[str, Any]]:
        conn = self.pool.get_connection()
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("SELECT ID, first_name, last_name FROM data")
            rows = cur.fetchall()
            return rows
        finally:
            try:
                cur.close()
            except Exception:
                pass
            conn.close()

    def fetch_by_id(self, id_: int) -> Optional[Dict[str, Any]]:
        conn = self.pool.get_connection()
        try:
            cur = conn.cursor(dictionary=True)
            cur.execute("SELECT ID, first_name, last_name FROM data WHERE ID = %s", (id_,))
            row = cur.fetchone()
            return row
        finally:
            try:
                cur.close()
            except Exception:
                pass
            conn.close()