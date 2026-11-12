from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from app.schemas.product import ProductResponse, ProductCreate
from app.models.product import ProductCategory

router = APIRouter(prefix="/products", tags=["Products & Stems"])

PRODUCTS_DB = [
    {
        "id": "prod_001",
        "shop_id": "shop_002",
        "name": "Midnight Crimson - 24 Red Roses",
        "description": "Hand-tied arrangement of 24 premium Grade-A Dutch red roses with eucalyptus in Korean paper.",
        "category": ProductCategory.ROSES,
        "price": 899.0,
        "original_price": 1199.0,
        "unit": "Bouquet",
        "image_url": "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=600&q=80",
        "rating": 4.9,
        "reviews_count": 142,
        "in_stock": True,
        "is_bestseller": True
    },
    {
        "id": "prod_002",
        "shop_id": "shop_001",
        "name": "Madurai Fragrant Jasmine (Malli)",
        "description": "Hand-picked morning harvest fresh Jasmine string. Pristine white blossoms tied with banana fiber.",
        "category": ProductCategory.FRESH_FLOWERS,
        "price": 240.0,
        "original_price": 280.0,
        "unit": "250 grams",
        "image_url": "https://images.unsplash.com/photo-1606041008023-472dfb5e530f?auto=format&fit=crop&w=600&q=80",
        "rating": 4.8,
        "reviews_count": 210,
        "in_stock": True,
        "is_bestseller": True
    },
    {
        "id": "prod_003",
        "shop_id": "shop_003",
        "name": "Ferrero & Rose Elegance Hamper",
        "description": "Box of 16 Ferrero Rocher chocolates paired with 10 long-stem preserved red roses and greeting note.",
        "category": ProductCategory.GIFT_HAMPERS,
        "price": 1499.0,
        "original_price": 1799.0,
        "unit": "Gift Box",
        "image_url": "https://images.unsplash.com/photo-1549465220-1a8b9238cd48?auto=format&fit=crop&w=600&q=80",
        "rating": 4.9,
        "reviews_count": 76,
        "in_stock": True,
        "is_bestseller": True
    }
]

@router.get("/", response_model=List[ProductResponse])
async def list_products(
    category: Optional[ProductCategory] = None,
    shop_id: Optional[str] = None,
    query: Optional[str] = None
):
    results = PRODUCTS_DB
    if category:
        results = [p for p in results if p["category"] == category]
    if shop_id:
        results = [p for p in results if p["shop_id"] == shop_id]
    if query:
        q = query.lower()
        results = [p for p in results if q in p["name"].lower() or q in p.get("description", "").lower()]
    return results

@router.get("/{product_id}", response_model=ProductResponse)
async def get_product(product_id: str):
    for p in PRODUCTS_DB:
        if p["id"] == product_id:
            return p
    raise HTTPException(status_code=404, detail="Product not found")

