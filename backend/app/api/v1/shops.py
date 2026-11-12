from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from app.schemas.shop import ShopResponse, DailyRatesUpdate
from app.models.shop import ShopType

router = APIRouter(prefix="/shops", tags=["Shops & Marketplaces"])

# Preloaded initial shops
SHOPS_DB = [
    {
        "id": "shop_001",
        "name": "Sri Lakshmi Flower Stall",
        "shop_type": ShopType.FLOWER_SHOP,
        "address": "100ft Road, Near Metro Pillar 84, Indiranagar, Bengaluru",
        "latitude": 12.9716,
        "longitude": 77.5946,
        "rating": 4.8,
        "total_reviews": 248,
        "image_url": "https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=600&q=80",
        "is_verified": True,
        "is_featured": True,
        "is_open": True,
        "owner_name": "Muthu Kumar",
        "contact_phone": "+91 98450 12345",
        "daily_rates": {
            "Fresh Jasmine (Madurai Malli)": 480.0,
            "Dutch Red Roses (20 stems)": 280.0,
            "Yellow Marigold (Genda kg)": 120.0,
            "Lotus (Pooja Pair)": 80.0
        }
    },
    {
        "id": "shop_002",
        "name": "Petals & Blooms Studio",
        "shop_type": ShopType.BOUQUET_SHOP,
        "address": "5th Block, 80ft Road, Koramangala, Bengaluru",
        "latitude": 12.9352,
        "longitude": 77.6245,
        "rating": 4.9,
        "total_reviews": 512,
        "image_url": "https://images.unsplash.com/photo-1526047932273-341f2a7631f9?auto=format&fit=crop&w=600&q=80",
        "is_verified": True,
        "is_featured": True,
        "is_open": True,
        "owner_name": "Ananya Sharma",
        "contact_phone": "+91 98451 98765",
        "daily_rates": {
            "Stem Red Rose (Single)": 35.0,
            "Stem White Asiatic Lily": 75.0,
            "Blue Dendrobium Orchid": 95.0
        }
    },
    {
        "id": "shop_003",
        "name": "The Velvet Ribbon Gifts & Florals",
        "shop_type": ShopType.GIFT_SHOP,
        "address": "27th Main, Sector 1, HSR Layout, Bengaluru",
        "latitude": 12.9121,
        "longitude": 77.6446,
        "rating": 4.7,
        "total_reviews": 189,
        "image_url": "https://images.unsplash.com/photo-1513519245088-0e12902e5a38?auto=format&fit=crop&w=600&q=80",
        "is_verified": True,
        "is_featured": False,
        "is_open": True,
        "owner_name": "Vikram Joshi",
        "contact_phone": "+91 99160 55443",
        "daily_rates": {
            "Luxury Ferrero Hamper": 850.0,
            "Handmade Greeting Cards": 120.0
        }
    }
]

@router.get("/", response_model=List[ShopResponse])
async def list_shops(
    shop_type: Optional[ShopType] = None,
    lat: Optional[float] = Query(default=12.9716),
    lng: Optional[float] = Query(default=77.5946),
    radius_km: Optional[float] = Query(default=10.0)
):
    if shop_type:
        return [s for s in SHOPS_DB if s["shop_type"] == shop_type]
    return SHOPS_DB

@router.get("/{shop_id}", response_model=ShopResponse)
async def get_shop_details(shop_id: str):
    for s in SHOPS_DB:
        if s["id"] == shop_id:
            return s
    raise HTTPException(status_code=404, detail="Shop not found")

@router.put("/{shop_id}/daily-rates", response_model=ShopResponse)
async def update_daily_rates(shop_id: str, payload: DailyRatesUpdate):
    for s in SHOPS_DB:
        if s["id"] == shop_id:
            s["daily_rates"].update(payload.rates)
            return s
    raise HTTPException(status_code=404, detail="Shop not found")

