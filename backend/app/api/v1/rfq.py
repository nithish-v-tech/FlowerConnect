from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from datetime import datetime
from app.schemas.rfq import RFQCreate, RFQResponse
from app.services.matching_engine import FairMerchantMatchingEngine
from app.services.quotation_service import QuotationManagementService
from app.api.v1.shops import SHOPS_DB

router = APIRouter(prefix="/rfq", tags=["Dynamic Quotations - RFQ"])

RFQ_DB = []

@router.post("/", response_model=RFQResponse)
async def create_rfq(payload: RFQCreate):
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
    
    # Run fair matching engine to find matching shops
    matched_shops = FairMerchantMatchingEngine.match_nearby_merchants(
        customer_lat=payload.latitude,
        customer_lng=payload.longitude,
        merchants=SHOPS_DB,
        max_radius_km=5.0
    )
    
    rfq_data["matched_merchants_count"] = len(matched_shops)
    RFQ_DB.append(rfq_data)
    return rfq_data

@router.get("/", response_model=List[RFQResponse])
async def list_rfqs(customer_id: Optional[str] = None):
    if customer_id:
        return [r for r in RFQ_DB if r["customer_id"] == customer_id]
    return RFQ_DB

@router.get("/{rfq_id}", response_model=RFQResponse)
async def get_rfq(rfq_id: str):
    for r in RFQ_DB:
        if r["id"] == rfq_id:
            return r
    raise HTTPException(status_code=404, detail="RFQ not found")

