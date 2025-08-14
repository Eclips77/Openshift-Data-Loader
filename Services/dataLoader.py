from fastapi import FastAPI
from dal import SQLDAL
app = FastAPI()
dal = SQLDAL()



@app.get("/data")
async def get_data_from_db():
    """Fetch all data from the database."""
    data = dal.get_all_data()
    if not data:
        return {"message": "No data found."}
    return {"data": data}
   

