from mysql.connector import connect, Error
from Infrastructure import config

class SQLDAL:
    def __init__(self):
        self.connection = self.get_connection()

    def get_connection(self):
        try:
            return connect(
                host=config.LOCALHOST,
                user=config.USER,
                password=config.PASSWORD,
                database=config.DATABASE
            )
        except Error as e:
            print(f"Connection failed: {e}")
            return None


    def get_all_data(self) -> dict:
        """_summary_

        Returns:
            list: list of dictionaries containing all the data in the table
        """
        if self.connection is None:
            print("No database connection.")
            return {}
        cursor = self.connection.cursor(dictionary=True)
        try:
            cursor.execute(f"SELECT * FROM {config.TABLE}")
            rows = cursor.fetchall()
            return rows
        except Error as ex:
            print(f"Error retrieving agents: {ex}")
            return {}
        finally:
            cursor.close()