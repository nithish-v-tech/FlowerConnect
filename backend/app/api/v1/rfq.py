from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.models.shop import Shop
from app.models.rfq import RFQRequest, DeliveryPreference, RFQStatus
from app.schemas.rfq import RFQCreate, RFQResponse
from app.services.matching_engine import FairMerchantMatchingEngine
from app.services.quotation_service import QuotationManagementService

router = APIRouter(prefix="/rfq", tags=["Dynamic Quotations - RFQ"])

# Deprecated legacy variable kept for backwards-compatibility imports
RFQ_DB: List = []

@router.post("/", response_model=RFQResponse)
async def create_rfq(payload: RFQCreate, db: AsyncSession = Depends(get_db)):
    rfq_data = QuotationManagementService.create_rfq(
        customer_id=payload.customer_id,
        customer_name=payload.customer_name,
        title=payload.title,
        flower_type=payload.flower_type,
        quantity_description=payload.quantity_description,
        delivery_preference=payload.delivery_preference.value,
        delivery_address=payload.delivery_address,
        latitude=payload.latitude,
        longitude=payload.longitude,
        target_budget=payload.target_budget,
        need_by_hours=payload.need_by_hours
    )

    # Fetch verified shops from database
    result = await db.execute(select(Shop).where(Shop.is_verified == True))
    shops = result.scalars().all()
    shops_dicts = [
        {
            "id": s.id,
            "name": s.name,
            "latitude": s.latitude,
            "longitude": s.longitude,
            "rating": s.rating,
            "total_reviews": s.total_reviews,
            "is_open": s.is_open,
        }
        for s in shops
    ]

    # Run fair matching engine to find matching shops
    matched_shops = FairMerchantMatchingEngine.match_nearby_merchants(
        customer_lat=payload.latitude,
        customer_lng=payload.longitude,
        merchants=shops_dicts,
        max_radius_km=5.0
    )

    # Persist RFQ to persistent SQLite database
    new_rfq = RFQRequest(
        id=rfq_data["id"],
        customer_id=rfq_data["customer_id"],
        customer_name=rfq_data["customer_name"],
        title=rfq_data["title"],
        flower_type=rfq_data["flower_type"],
        quantity_description=rfq_data["quantity_description"],
        occasion=rfq_data.get("occasion"),
        delivery_preference=DeliveryPreference(rfq_data["delivery_preference"]),
        delivery_address=rfq_data["delivery_address"],
        latitude=rfq_data.get("latitude", 12.9716),
        longitude=rfq_data.get("longitude", 77.5946),
        target_budget=rfq_data.get("target_budget"),
        need_by=datetime.fromisoformat(rfq_data["need_by"]),
        status=RFQStatus(rfq_data["status"]),
        created_at=datetime.fromisoformat(rfq_data["created_at"]),
        expires_at=datetime.fromisoformat(rfq_data["expires_at"]),
    )
    db.add(new_rfq)
    await db.commit()
    await db.refresh(new_rfq)

    return new_rfq

@router.get("/", response_model=List[RFQResponse])
async def list_rfqs(customer_id: Optional[str] = None, db: AsyncSession = Depends(get_db)):
    query = select(RFQRequest)
    if customer_id:
        query = query.where(RFQRequest.customer_id == customer_id)
    query = query.order_by(RFQRequest.created_at.desc())
    result = await db.execute(query)
    return result.scalars().all()

@router.get("/{rfq_id}", response_model=RFQResponse)
async def get_rfq(rfq_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(RFQRequest).where(RFQRequest.id == rfq_id))
    rfq = result.scalars().first()
    if not rfq:
        raise HTTPException(status_code=404, detail="RFQ not found")
    return rfq
