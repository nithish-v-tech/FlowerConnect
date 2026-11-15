import uuid
from datetime import datetime
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.models.order import Order, OrderStatus, PaymentStatus, OrderFulfillment, PaymentMethod
from app.schemas.order import OrderCreate, OrderResponse

router = APIRouter(prefix="/orders", tags=["Customer Orders & Fulfillment"])

@router.get("/")
async def list_orders(
    customer_id: Optional[str] = None,
    shop_id: Optional[str] = None,
    driver_id: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    query = select(Order)
    if customer_id:
        query = query.where(Order.customer_id == customer_id)
    if shop_id:
        query = query.where(Order.shop_id == shop_id)
    if driver_id:
        query = query.where(Order.driver_id == driver_id)

    query = query.order_by(Order.created_at.desc())
    result = await db.execute(query)
    orders = result.scalars().all()

    # Format into response dictionaries
    return [
        {
            "id": o.id,
            "customer_id": o.customer_id,
            "customer_name": o.customer_name,
            "customer_phone": o.customer_phone,
            "shop_id": o.shop_id,
            "shop_name": o.shop_name,
            "quotation_id": o.quotation_id,
            "items": o.items_json,
            "items_total": o.items_total,
            "delivery_fee": o.delivery_fee,
            "platform_commission": o.platform_commission,
            "grand_total": o.grand_total,
            "fulfillment": o.fulfillment,
            "payment_method": o.payment_method,
            "payment_status": o.payment_status,
            "status": o.status,
            "delivery_address": o.delivery_address,
            "delivery_otp": o.delivery_otp,
            "driver_name": o.driver_name,
            "driver_phone": o.driver_phone,
            "is_surprise_delivery": o.is_surprise_delivery,
            "surprise_recipient_name": o.surprise_recipient_name,
            "surprise_note": o.surprise_note,
            "created_at": o.created_at.isoformat() if o.created_at else None,
        }
        for o in orders
    ]

@router.get("/{order_id}")
async def get_order(order_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Order).where(Order.id == order_id))
    o = result.scalars().first()
    if not o:
        raise HTTPException(status_code=404, detail="Order not found")

    return {
        "id": o.id,
        "customer_id": o.customer_id,
        "customer_name": o.customer_name,
        "customer_phone": o.customer_phone,
        "shop_id": o.shop_id,
        "shop_name": o.shop_name,
        "quotation_id": o.quotation_id,
        "items": o.items_json,
        "items_total": o.items_total,
        "delivery_fee": o.delivery_fee,
        "platform_commission": o.platform_commission,
        "grand_total": o.grand_total,
        "fulfillment": o.fulfillment,
        "payment_method": o.payment_method,
        "payment_status": o.payment_status,
        "status": o.status,
        "delivery_address": o.delivery_address,
        "delivery_otp": o.delivery_otp,
        "driver_name": o.driver_name,
        "driver_phone": o.driver_phone,
        "is_surprise_delivery": o.is_surprise_delivery,
        "surprise_recipient_name": o.surprise_recipient_name,
        "surprise_note": o.surprise_note,
        "created_at": o.created_at.isoformat() if o.created_at else None,
    }

@router.post("/", status_code=status.HTTP_201_CREATED)
async def place_order(payload: OrderCreate, db: AsyncSession = Depends(get_db)):
    order_id = f"ORD-{uuid.uuid4().hex[:5].upper()}"

    items_total = sum(i.unit_price * i.quantity for i in payload.items)
    delivery_fee = 40.0 if payload.fulfillment == OrderFulfillment.HOME_DELIVERY else 0.0
    platform_commission = round(items_total * 0.10, 2)
    grand_total = items_total + delivery_fee + 15.0  # + Platform handling fee

    order = Order(
        id=order_id,
        customer_id=payload.customer_id,
        customer_name=payload.customer_name,
        customer_phone=payload.customer_phone,
        shop_id=payload.shop_id,
        shop_name=payload.shop_name,
        quotation_id=None,
        items_json=[i.model_dump() for i in payload.items],
        items_total=items_total,
        delivery_fee=delivery_fee,
        platform_commission=platform_commission,
        grand_total=grand_total,
        fulfillment=payload.fulfillment,
        payment_method=payload.payment_method,
        payment_status=PaymentStatus.PENDING,
        status=OrderStatus.PLACED,
        delivery_address=payload.delivery_address,
        delivery_otp=str(uuid.uuid4().int)[:4],
        driver_id=None,
        driver_name=None,
        driver_phone=None,
        is_surprise_delivery=payload.is_surprise_delivery,
        surprise_recipient_name=payload.surprise_recipient_name,
        surprise_note=payload.surprise_note,
        created_at=datetime.utcnow()
    )

    db.add(order)
    await db.commit()
    await db.refresh(order)

    return {
        "status": "success",
        "message": f"Order {order_id} placed successfully!",
        "order_id": order_id,
        "grand_total": grand_total,
        "order": {
            "id": order.id,
            "customer_id": order.customer_id,
            "customer_name": order.customer_name,
            "shop_name": order.shop_name,
            "status": order.status,
            "delivery_otp": order.delivery_otp,
            "grand_total": order.grand_total,
        }
    }

@router.patch("/{order_id}/status")
async def update_order_status(order_id: str, new_status: OrderStatus, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalars().first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    order.status = new_status
    await db.commit()
    await db.refresh(order)

    return {
        "status": "success",
        "message": f"Order {order_id} status updated to {new_status}",
        "order_id": order_id,
        "new_status": new_status,
    }
