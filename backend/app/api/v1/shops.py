from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.models.shop import Shop, ShopType
from app.schemas.shop import ShopResponse, DailyRatesUpdate

router = APIRouter(prefix="/shops", tags=["Shops & Marketplaces"])

@router.get("/", response_model=List[ShopResponse])
async def list_shops(
    shop_type: Optional[ShopType] = None,
    lat: Optional[float] = Query(default=12.9716),
    lng: Optional[float] = Query(default=77.5946),
    radius_km: Optional[float] = Query(default=10.0),
    db: AsyncSession = Depends(get_db)
):
    query = select(Shop)
    if shop_type:
        query = query.where(Shop.shop_type == shop_type)

    result = await db.execute(query)
    shops = result.scalars().all()
    return shops

@router.get("/{shop_id}", response_model=ShopResponse)
async def get_shop_details(shop_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Shop).where(Shop.id == shop_id))
    shop = result.scalars().first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")
    return shop

@router.put("/{shop_id}/daily-rates", response_model=ShopResponse)
async def update_daily_rates(shop_id: str, payload: DailyRatesUpdate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Shop).where(Shop.id == shop_id))
    shop = result.scalars().first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")

    updated_rates = dict(shop.daily_rates or {})
    updated_rates.update(payload.rates)
    shop.daily_rates = updated_rates

    await db.commit()
    await db.refresh(shop)
    return shop
