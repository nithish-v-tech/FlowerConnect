from fastapi import APIRouter, HTTPException
from typing import Dict, Any, List
from app.api.v1.orders import ORDERS_DB
from app.models.order import OrderStatus, OrderFulfillment

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
async def get_assigned_trips():
    if not DRIVER_STATE["is_online"]:
        return []
    return [
        o for o in ORDERS_DB
        if o.get("fulfillment") == OrderFulfillment.HOME_DELIVERY
        and o.get("status") in [OrderStatus.OUT_FOR_DELIVERY, OrderStatus.PREPARING, OrderStatus.CONFIRMED]
    ]

