from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime
from app.models.order import OrderStatus, OrderFulfillment, PaymentMethod, PaymentStatus

class OrderItemSchema(BaseModel):
    product_id: str
    product_name: str
    unit_price: float
    quantity: int
    unit: str
    image_url: Optional[str] = None

class OrderCreate(BaseModel):
    customer_id: str
    customer_name: str
    customer_phone: str
    shop_id: str
    shop_name: str
    items: List[OrderItemSchema]
    fulfillment: OrderFulfillment = OrderFulfillment.HOME_DELIVERY
    payment_method: PaymentMethod = PaymentMethod.UPI
    delivery_address: str
    is_surprise_delivery: bool = False
    surprise_recipient_name: Optional[str] = None
    surprise_note: Optional[str] = None

class OrderResponse(BaseModel):
    id: str
    customer_id: str
    customer_name: str
    customer_phone: str
    shop_id: str
    shop_name: str
    quotation_id: Optional[str]
    items_total: float
    delivery_fee: float
    platform_commission: float
    grand_total: float
    fulfillment: OrderFulfillment
    payment_method: PaymentMethod
    payment_status: PaymentStatus
    status: OrderStatus
    delivery_address: str
    delivery_otp: str
    driver_name: Optional[str]
    driver_phone: Optional[str]
    is_surprise_delivery: bool
    surprise_recipient_name: Optional[str]
    surprise_note: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class VerifyDeliveryOtpRequest(BaseModel):
    order_id: str
    otp: str

