from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    DB_HOST: str
    DB_PORT: int = 3306
    DB_USER: str
    DB_PASSWORD: str
    DB_NAME: str
    POOL_NAME: str = "dataloader_pool"
    POOL_SIZE: int = 5
    API_TITLE: str = "Data Loader API"
    API_VERSION: str = "1.0.0"

    model_config = SettingsConfigDict(env_file=None, extra="ignore")

settings = Settings()