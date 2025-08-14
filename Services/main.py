from fastapi import FastAPI
from config import settings
from dataLoader import router

app = FastAPI(title=settings.API_TITLE, version=settings.API_VERSION)
app.include_router(router)


