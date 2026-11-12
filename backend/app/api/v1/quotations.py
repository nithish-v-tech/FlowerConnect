from fastapi import APIRouter, HTTPException, status
from typing import List, Dict, Any
from app.schemas.quotation import QuotationCreate, QuotationResponse, QuotationAcceptRequest
from app.services.quotation_service import QuotationManagementService
from app.api.v1.rfq import RFQ_DB
from app.api.v1.orders import ORDERS_DB

router = APIRouter(prefix="/quotations", tags=["Dynamic Quotations - Bidding"])

QUOTATIONS_DB: List[Dict[str, Any]] = []

@router.post("/submit", response_model=QuotationResponse, status_code=status.HTTP_201_CREATED)
async def submit_quotation(payload: QuotationCreate):
    # Verify RFQ exists and is active
    rfq = next((r for r in RFQ_DB if r["id"] == payload.rfq_id), None)
    if not rfq:
        raise HTTPException(status_code=404, detail="RFQ not found")
    if rfq["status"] in ["ACCEPTED", "EXPIRED", "CANCELLED"]:
        raise HTTPException(status_code=400, detail=f"RFQ is {rfq['status']}. Cannot submit new quotes.")

    quote_data = QuotationManagementService.submit_quote(
        rfq_id=payload.rfq_id,
        merchant_id=payload.merchant_id,
        shop_name=payload.shop_name,
        merchant_phone=payload.merchant_phone,
        merchant_rating=payload.merchant_rating,
        distance_km=payload.distance_km,
        quoted_price=payload.quoted_price,
        delivery_fee=payload.delivery_fee,
        prep_time_minutes=payload.prep_time_minutes,
        notes=payload.notes or "",
        freshness_guarantee=payload.freshness_guarantee or "100% farm fresh"
    )

    QUOTATIONS_DB.append(quote_data)
    rfq["status"] = "QUOTES_RECEIVED"
    return quote_data

@router.get("/rfq/{rfq_id}", response_model=List[QuotationResponse])
async def get_quotations_for_rfq(rfq_id: str):
    return [q for q in QUOTATIONS_DB if q["rfq_id"] == rfq_id]

@router.post("/accept")
async def accept_quotation(payload: QuotationAcceptRequest):
    rfq = next((r for r in RFQ_DB if r["id"] == payload.rfq_id), None)
    if not rfq:
        raise HTTPException(status_code=404, detail="RFQ not found")
    if rfq["status"] == "ACCEPTED":
        raise HTTPException(status_code=400, detail="A quotation has already been accepted and locked for this RFQ.")

    quotes_for_rfq = [q for q in QUOTATIONS_DB if q["rfq_id"] == payload.rfq_id]
    if not quotes_for_rfq:
        raise HTTPException(status_code=404, detail="No quotations found for this RFQ.")

    result = QuotationManagementService.accept_and_lock_quotation(
        rfq=rfq,
        quotations=quotes_for_rfq,
        accepted_quote_id=payload.quotation_id
    )

    # Push to confirmed orders
    ORDERS_DB.append(result["confirmed_order"])

    return {
        "message": "Quotation accepted successfully. Order locked and confirmed.",
        "order": result["confirmed_order"],
        "rfq_status": rfq["status"]
    }

