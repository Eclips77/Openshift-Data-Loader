from pydantic import BaseModel

class Record(BaseModel):
    ID: int
    first_name: str
    last_name: str