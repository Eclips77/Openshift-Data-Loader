from fastapi import FastAPI
import mysql.connector


app = FastAPI()


@app.get("/data")
async def get_data_from_db():
    pass

