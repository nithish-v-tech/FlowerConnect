import enum
from datetime import datetime
from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, Enum, ForeignKey
from app.core.database import Base

class ProductCategory(str, enum.Enum):
    FRESH_FLOWERS = "FRESH_FLOWERS"
    READY_BOUQUETS = "READY_BOUQUETS"
    ROSES = "ROSES"
    LILIES = "LILIES"
    EXOTICS = "EXOTICS"
    CHOCOLATES = "CHOCOLATES"
    PLUSH_TOYS = "PLUSH_TOYS"
    GREETING_CARDS = "GREETING_CARDS"
    GIFT_HAMPERS = "GIFT_HAMPERS"
    CUSTOM_BOUQUET = "CUSTOM_BOUQUET"

class Product(Base):
    __tablename__ = "products"

    id = Column(String(36), primary_key=True, index=True)
    shop_id = Column(String(36), ForeignKey("shops.id"), nullable=False)
    name = Column(String(150), nullable=False)
    description = Column(String(500), nullable=True)
    category = Column(Enum(ProductCategory), default=ProductCategory.FRESH_FLOWERS, nullable=False)
    price = Column(Float, nullable=False)
    original_price = Column(Float, nullable=True)
    unit = Column(String(50), default="piece")
    image_url = Column(String(255), nullable=True)
    rating = Column(Float, default=4.8)
    reviews_count = Column(Integer, default=24)
    in_stock = Column(Boolean, default=True)
    is_bestseller = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

