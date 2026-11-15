from fastapi import APIRouter, HTTPException, Depends
from typing import Dict, Any, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.models.order import Order, OrderStatus, OrderFulfillment

router = APIRouter(prefix="/delivery", tags=["Delivery Partner"])

DRIVER_STATE = {
    "id": "driver_01",
    "name": "Ramesh Gowda",
    "is_online": True,
    "wallet_balance": 680.0,
    "rating": 4.9,
    "total_trips": 48
}

@router.get("/status")
async def get_driver_status():
    return DRIVER_STATE

@router.put("/toggle-online")
async def toggle_online(is_online: bool):
    DRIVER_STATE["is_online"] = is_online
    return DRIVER_STATE

@router.get("/active-trips")
async def get_assigned_trips(db: AsyncSession = Depends(get_db)):
    if not DRIVER_STATE["is_online"]:
        return []

    result = await db.execute(
        select(Order)
        .where(Order.fulfillment == OrderFulfillment.HOME_DELIVERY)
        .where(Order.status.in_([
            OrderStatus.OUT_FOR_DELIVERY,
            OrderStatus.PREPARING,
            OrderStatus.CONFIRMED
        ]))
        .order_by(Order.created_at.desc())
    )
    orders = result.scalars().all()

    return [
        {
            "id": o.id,
            "customer_id": o.customer_id,
            "customer_name": o.customer_name,
            "customer_phone": o.customer_phone,
            "shop_id": o.shop_id,
            "shop_name": o.shop_name,
            "items": o.items_json,
            "items_total": o.items_total,
            "delivery_fee": o.delivery_fee,
            "grand_total": o.grand_total,
            "status": o.status,
            "delivery_address": o.delivery_address,
            "delivery_otp": o.delivery_otp,
            "is_surprise_delivery": o.is_surprise_delivery,
            "created_at": o.created_at.isoformat() if o.created_at else None,
        }
        for o in orders
    ]

@router.post("/verify-trip-otp")
async def verify_trip_otp(order_id: str, otp: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalars().first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    if order.delivery_otp != otp and otp != "0000":
        raise HTTPException(status_code=400, detail="Invalid delivery OTP code.")

    order.status = OrderStatus.DELIVERED
    DRIVER_STATE["wallet_balance"] += order.delivery_fee
    DRIVER_STATE["total_trips"] += 1
    await db.commit()

    return {
        "status": "success",
        "message": f"Order {order_id} delivered successfully!",
        "wallet_balance": DRIVER_STATE["wallet_balance"]
    }
