from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    APP_NAME: str = "FlowerConnect Hyperlocal API"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    API_V1_STR: str = "/api/v1"
    
    SECRET_KEY: str = "flowerconnect-super-secure-production-secret-key-32chars"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    
    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./flowerconnect.db"
    
    # Dynamic Quotation Parameters
    DEFAULT_RFQ_RADIUS_KM: float = 5.0
    DEFAULT_RFQ_EXPIRY_MINUTES: int = 45
    DEFAULT_QUOTATION_LOCK_MINUTES: int = 30
    
    # Financial Configuration
    DEFAULT_PLATFORM_COMMISSION_PERCENT: float = 10.0
    DEFAULT_DELIVERY_BASE_FEE: float = 40.0
    DELIVERY_PARTNER_SHARE_PERCENT: float = 80.0
    
    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["*"]

    model_config = SettingsConfigDict(env_file=".env", extra="allow", case_sensitive=True)

settings = Settings()
