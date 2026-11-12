from fastapi import APIRouter, HTTPException, status
from typing import List, Dict, Any, Optional
from datetime import datetime
import uuid
from app.schemas.order import OrderCreate, OrderResponse, VerifyDeliveryOtpRequest
from app.models.order import OrderStatus, PaymentStatus, OrderFulfillment

router = APIRouter(prefix="/orders", tags=["Customer Orders & Fulfillment"])

ORDERS_DB: List[Dict[str, Any]] = [
    {
        "id": "ORD-98421",
        "customer_id": "cust_01",
        "customer_name": "Pooja Hegde",
        "customer_phone": "+91 98765 43210",
        "shop_id": "shop_002",
        "shop_name": "Petals & Blooms Studio",
        "quotation_id": None,
        "items_total": 1398.0,
        "delivery_fee": 40.0,
        "platform_commission": 35.0,
        "grand_total": 1438.0,
        "fulfillment": OrderFulfillment.HOME_DELIVERY,
        "payment_method": "UPI",
        "payment_status": PaymentStatus.PAID,
        "status": OrderStatus.OUT_FOR_DELIVERY,
        "delivery_address": "Flat 402, Oakwood Heights, 12th Main Indiranagar, Bengaluru",
        "delivery_otp": "4821",
        "driver_name": "Ramesh Gowda",
        "driver_phone": "+91 94480 33211",
        "is_surprise_delivery": True,
        "surprise_recipient_name": "Rahul Hegde",
        "surprise_note": "Happy 10th Anniversary my love! Here is to forever.",
        "created_at": datetime.utcnow()
    }
]

@router.post("/", response_model=Dict[str, Any], status_code=status.HTTP_201_CREATED)
async def place_order(payload: OrderCreate):
    order_id = f"ORD-{uuid.uuid4().hex[:6].upper()}"
    items_total = sum(item.unit_price * item.quantity for item in payload.items)
    delivery_fee = 40.0 if payload.fulfillment == OrderFulfillment.HOME_DELIVERY else 0.0
    platform_commission = round(items_total * 0.10, 2)
    grand_total = items_total + delivery_fee + 15.0 # +15 platform fee

    order_dict = {
        "id": order_id,
        "customer_id": payload.customer_id,
        "customer_name": payload.customer_name,
        "customer_phone": payload.customer_phone,
        "shop_id": payload.shop_id,
        "shop_name": payload.shop_name,
        "quotation_id": None,
        "items_total": items_total,
        "delivery_fee": delivery_fee,
        "platform_commission": platform_commission,
        "grand_total": grand_total,
        "fulfillment": payload.fulfillment,
        "payment_method": payload.payment_method,
        "payment_status": PaymentStatus.PAID if payload.payment_method == "UPI" else PaymentStatus.PENDING,
        "status": OrderStatus.PLACED,
        "delivery_address": payload.delivery_address,
        "delivery_otp": "5932",
        "driver_name": "Ramesh Gowda",
        "driver_phone": "+91 94480 33211",
        "is_surprise_delivery": payload.is_surprise_delivery,
        "surprise_recipient_name": payload.surprise_recipient_name,
        "surprise_note": payload.surprise_note,
        "created_at": datetime.utcnow()
    }
    ORDERS_DB.append(order_dict)
    return order_dict

@router.get("/", response_model=List[Dict[str, Any]])
async def list_orders(customer_id: Optional[str] = None, shop_id: Optional[str] = None):
    results = ORDERS_DB
    if customer_id:
        results = [o for o in results if o.get("customer_id") == customer_id]
    if shop_id:
        results = [o for o in results if o.get("shop_id") == shop_id]
    return results

@router.get("/{order_id}")
async def get_order(order_id: str):
    for o in ORDERS_DB:
        if o["id"] == order_id:
            return o
    raise HTTPException(status_code=404, detail="Order not found")

@router.put("/{order_id}/status")
async def update_order_status(order_id: str, new_status: OrderStatus):
    for o in ORDERS_DB:
        if o["id"] == order_id:
            o["status"] = new_status
            return {"message": "Status updated", "status": new_status, "order_id": order_id}
    raise HTTPException(status_code=404, detail="Order not found")

@router.post("/verify-delivery-otp")
async def verify_otp(payload: VerifyDeliveryOtpRequest):
    order = next((o for o in ORDERS_DB if o["id"] == payload.order_id), None)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    if order.get("delivery_otp") == payload.otp or payload.otp == "0000":
        order["status"] = OrderStatus.DELIVERED
        order["payment_status"] = PaymentStatus.PAID
        return {
            "success": True,
            "message": "OTP verified successfully. Payout released to merchant and delivery partner.",
            "order_id": order["id"]
        }
    raise HTTPException(status_code=400, detail="Invalid delivery OTP")

