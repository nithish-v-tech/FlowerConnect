import uuid
from datetime import datetime
from fastapi import APIRouter, HTTPException, Depends, status
from typing import List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.models.order import Order, OrderStatus, OrderFulfillment, PaymentMethod, PaymentStatus
from app.models.quotation import Quotation, QuotationStatus
from app.models.rfq import RFQRequest, DeliveryPreference, RFQStatus
from app.schemas.quotation import QuotationCreate, QuotationResponse, QuotationAcceptRequest
from app.services.quotation_service import QuotationManagementService

router = APIRouter(prefix="/quotations", tags=["Dynamic Quotations - Bidding"])

# Deprecated legacy variable kept for backwards-compatibility imports
QUOTATIONS_DB: List[Dict[str, Any]] = []

@router.post("/submit", response_model=QuotationResponse, status_code=status.HTTP_201_CREATED)
async def submit_quotation(payload: QuotationCreate, db: AsyncSession = Depends(get_db)):
    # Verify RFQ exists and is active in persistent database
    result = await db.execute(select(RFQRequest).where(RFQRequest.id == payload.rfq_id))
    rfq = result.scalars().first()
    if not rfq:
        raise HTTPException(status_code=404, detail="RFQ not found")
    if rfq.status in [RFQStatus.ACCEPTED, RFQStatus.EXPIRED, RFQStatus.CANCELLED]:
        raise HTTPException(status_code=400, detail=f"RFQ is {rfq.status.value}. Cannot submit new quotes.")

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

    # Persist quotation to database
    new_quote = Quotation(
        id=quote_data["id"],
        rfq_id=quote_data["rfq_id"],
        merchant_id=quote_data["merchant_id"],
        shop_name=quote_data["shop_name"],
        merchant_phone=quote_data["merchant_phone"],
        merchant_rating=quote_data["merchant_rating"],
        distance_km=quote_data["distance_km"],
        quoted_price=quote_data["quoted_price"],
        delivery_fee=quote_data["delivery_fee"],
        prep_time_minutes=quote_data["prep_time_minutes"],
        notes=quote_data.get("notes"),
        freshness_guarantee=quote_data.get("freshness_guarantee"),
        status=QuotationStatus.PENDING,
        submitted_at=datetime.fromisoformat(quote_data["submitted_at"]),
        expires_at=datetime.fromisoformat(quote_data["expires_at"]),
    )
    db.add(new_quote)
    rfq.status = RFQStatus.QUOTES_RECEIVED
    await db.commit()
    await db.refresh(new_quote)

    return new_quote

@router.get("/rfq/{rfq_id}", response_model=List[QuotationResponse])
async def get_quotations_for_rfq(rfq_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Quotation).where(Quotation.rfq_id == rfq_id))
    return result.scalars().all()

@router.post("/accept")
async def accept_quotation(payload: QuotationAcceptRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(RFQRequest).where(RFQRequest.id == payload.rfq_id))
    rfq = result.scalars().first()
    if not rfq:
        raise HTTPException(status_code=404, detail="RFQ not found")
    if rfq.status == RFQStatus.ACCEPTED:
        raise HTTPException(status_code=400, detail="A quotation has already been accepted and locked for this RFQ.")

    quotes_result = await db.execute(select(Quotation).where(Quotation.rfq_id == payload.rfq_id))
    quotes = quotes_result.scalars().all()
    if not quotes:
        raise HTTPException(status_code=404, detail="No quotations found for this RFQ.")

    winning_quote = next((q for q in quotes if q.id == payload.quotation_id), None)
    if not winning_quote:
        raise HTTPException(status_code=404, detail=f"Quotation {payload.quotation_id} not found.")

    # Atomically lock: Accept winner, reject competitors
    for q in quotes:
        if q.id == payload.quotation_id:
            q.status = QuotationStatus.ACCEPTED
        else:
            q.status = QuotationStatus.REJECTED

    rfq.status = RFQStatus.ACCEPTED
    rfq.accepted_quotation_id = payload.quotation_id

    # Create persistent order with unassigned driver and pending payment
    order_id = f"ORD-Q{uuid.uuid4().hex[:6].upper()}"
    commission_rate = 0.10
    commission = round(winning_quote.quoted_price * commission_rate, 2)
    grand_total = winning_quote.quoted_price + (winning_quote.delivery_fee if rfq.delivery_preference == DeliveryPreference.HOME_DELIVERY else 0.0)

    new_order = Order(
        id=order_id,
        customer_id=rfq.customer_id,
        customer_name=rfq.customer_name,
        customer_phone="+919876543210",
        shop_id=winning_quote.merchant_id,
        shop_name=winning_quote.shop_name,
        quotation_id=winning_quote.id,
        items_json=[{
            "product_id": f"custom_{rfq.id}",
            "product_name": f"{rfq.flower_type} ({rfq.quantity_description})",
            "unit_price": winning_quote.quoted_price,
            "quantity": 1,
            "unit": "Custom Quotation"
        }],
        items_total=winning_quote.quoted_price,
        delivery_fee=winning_quote.delivery_fee if rfq.delivery_preference == DeliveryPreference.HOME_DELIVERY else 0.0,
        platform_commission=commission,
        grand_total=grand_total,
        fulfillment=OrderFulfillment.HOME_DELIVERY if rfq.delivery_preference == DeliveryPreference.HOME_DELIVERY else OrderFulfillment.SELF_PICKUP,
        payment_method=PaymentMethod.UPI,
        payment_status=PaymentStatus.PENDING,
        status=OrderStatus.CONFIRMED,
        delivery_address=rfq.delivery_address,
        delivery_otp="4821",
        driver_id=None,
        driver_name=None,
        created_at=datetime.utcnow()
    )
    db.add(new_order)
    await db.commit()

    return {
        "message": "Quotation accepted successfully. Order locked and confirmed.",
        "order_id": order_id,
        "rfq_status": rfq.status.value,
        "winning_quotation_id": winning_quote.id
    }
