from pydantic import BaseModel
from typing import Optional
from app.models.product import ProductCategory

class ProductBase(BaseModel):
    name: str
    description: Optional[str] = None
    category: ProductCategory
    price: float
    original_price: Optional[float] = None
    unit: str = "piece"
    image_url: Optional[str] = None
    in_stock: bool = True
    is_bestseller: bool = False

class ProductCreate(ProductBase):
    shop_id: str

class ProductResponse(ProductBase):
    id: str
    shop_id: str
    rating: float
    reviews_count: int

    class Config:
        from_attributes = True

