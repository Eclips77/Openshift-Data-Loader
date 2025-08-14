from fastapi import FastAPI
from Services.config import settings
from Services.dataLoader import router

app = FastAPI(title=settings.API_TITLE, version=settings.API_VERSION)
app.include_router(router)