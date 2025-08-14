from fastapi import APIRouter, Depends, HTTPException
from typing import List
from .dal import DataLoaderDAL
from Services.models import Record

router = APIRouter()

def get_dal() -> DataLoaderDAL:
    return DataLoaderDAL()

@router.get("/health")
def health():
    return {"status": "ok"}

@router.get("/data", response_model=List[Record])
def get_all(dal: DataLoaderDAL = Depends(get_dal)):
    return dal.fetch_all()

@router.get("/data/{item_id}", response_model=Record)
def get_one(item_id: int, dal: DataLoaderDAL = Depends(get_dal)):
    row = dal.fetch_by_id(item_id)
    if not row:
        raise HTTPException(status_code=404, detail="Not found")
    return row