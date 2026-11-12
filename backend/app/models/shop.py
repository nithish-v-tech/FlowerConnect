import enum
from datetime import datetime
from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, Enum, ForeignKey, JSON
from app.core.database import Base

class ShopType(str, enum.Enum):
    FLOWER_SHOP = "FLOWER_SHOP"
    BOUQUET_SHOP = "BOUQUET_SHOP"
    GIFT_SHOP = "GIFT_SHOP"
    HYBRID = "HYBRID"

class Shop(Base):
    __tablename__ = "shops"

    id = Column(String(36), primary_key=True, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    name = Column(String(120), nullable=False)
    shop_type = Column(Enum(ShopType), default=ShopType.FLOWER_SHOP, nullable=False)
    address = Column(String(255), nullable=False)
    latitude = Column(Float, nullable=False, default=12.9716)
    longitude = Column(Float, nullable=False, default=77.5946)
    rating = Column(Float, default=4.8)
    total_reviews = Column(Integer, default=120)
    image_url = Column(String(255), nullable=True)
    is_verified = Column(Boolean, default=True)
    is_featured = Column(Boolean, default=False)
    is_open = Column(Boolean, default=True)
    owner_name = Column(String(100), nullable=False)
    contact_phone = Column(String(20), nullable=False)
    daily_rates = Column(JSON, default=dict)
    created_at = Column(DateTime, default=datetime.utcnow)

