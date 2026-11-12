from pydantic import BaseModel
from typing import Optional, Dict
from app.models.shop import ShopType

class ShopBase(BaseModel):
    name: str
    shop_type: ShopType = ShopType.FLOWER_SHOP
    address: str
    latitude: float = 12.9716
    longitude: float = 77.5946
    image_url: Optional[str] = None
    owner_name: str
    contact_phone: str
    daily_rates: Optional[Dict[str, float]] = {}

class ShopCreate(ShopBase):
    user_id: str

class ShopResponse(ShopBase):
    id: str
    rating: float
    total_reviews: int
    is_verified: bool
    is_featured: bool
    is_open: bool

    class Config:
        from_attributes = True

class DailyRatesUpdate(BaseModel):
    rates: Dict[str, float]

