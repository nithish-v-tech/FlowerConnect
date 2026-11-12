import enum
from datetime import datetime
from sqlalchemy import Column, String, Float, Boolean, DateTime, Enum, ForeignKey, JSON
from app.core.database import Base

class OrderStatus(str, enum.Enum):
    PLACED = "PLACED"
    CONFIRMED = "CONFIRMED"
    PREPARING = "PREPARING"
    OUT_FOR_DELIVERY = "OUT_FOR_DELIVERY"
    READY_FOR_PICKUP = "READY_FOR_PICKUP"
    DELIVERED = "DELIVERED"
    CANCELLED = "CANCELLED"

class OrderFulfillment(str, enum.Enum):
    HOME_DELIVERY = "HOME_DELIVERY"
    SELF_PICKUP = "SELF_PICKUP"

class PaymentMethod(str, enum.Enum):
    UPI = "UPI"
    CASH_ON_DELIVERY = "CASH_ON_DELIVERY"

class PaymentStatus(str, enum.Enum):
    PENDING = "PENDING"
    PAID = "PAID"
    FAILED = "FAILED"

class Order(Base):
    __tablename__ = "orders"

    id = Column(String(36), primary_key=True, index=True)
    customer_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    customer_name = Column(String(100), nullable=False)
    customer_phone = Column(String(20), nullable=False)
    shop_id = Column(String(36), ForeignKey("shops.id"), nullable=False)
    shop_name = Column(String(120), nullable=False)
    quotation_id = Column(String(36), nullable=True)
    items_json = Column(JSON, nullable=False)
    items_total = Column(Float, nullable=False)
    delivery_fee = Column(Float, default=40.0)
    platform_commission = Column(Float, default=25.0)
    grand_total = Column(Float, nullable=False)
    fulfillment = Column(Enum(OrderFulfillment), default=OrderFulfillment.HOME_DELIVERY, nullable=False)
    payment_method = Column(Enum(PaymentMethod), default=PaymentMethod.UPI, nullable=False)
    payment_status = Column(Enum(PaymentStatus), default=PaymentStatus.PAID, nullable=False)
    status = Column(Enum(OrderStatus), default=OrderStatus.PLACED, nullable=False)
    delivery_address = Column(String(255), nullable=False)
    delivery_otp = Column(String(6), default="4821")
    driver_id = Column(String(36), nullable=True)
    driver_name = Column(String(100), default="Ramesh Gowda")
    driver_phone = Column(String(20), default="+91 94480 33211")
    driver_lat = Column(Float, default=12.9716)
    driver_lng = Column(Float, default=77.5946)
    is_surprise_delivery = Column(Boolean, default=False)
    surprise_recipient_name = Column(String(100), nullable=True)
    surprise_note = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    estimated_delivery_time = Column(DateTime, nullable=True)

