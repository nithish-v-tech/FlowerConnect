import enum
from datetime import datetime
from sqlalchemy import Column, String, Float, DateTime, Enum, ForeignKey
from app.core.database import Base

class DeliveryPreference(str, enum.Enum):
    HOME_DELIVERY = "HOME_DELIVERY"
    SELF_PICKUP = "SELF_PICKUP"

class RFQStatus(str, enum.Enum):
    BROADCASTING = "BROADCASTING"
    QUOTES_RECEIVED = "QUOTES_RECEIVED"
    ACCEPTED = "ACCEPTED"
    EXPIRED = "EXPIRED"
    CANCELLED = "CANCELLED"

class RFQRequest(Base):
    __tablename__ = "rfq_requests"

    id = Column(String(36), primary_key=True, index=True)
    customer_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    customer_name = Column(String(100), nullable=False)
    title = Column(String(200), nullable=False)
    flower_type = Column(String(100), nullable=False)
    quantity_description = Column(String(200), nullable=False)
    occasion = Column(String(100), nullable=True)
    delivery_preference = Column(Enum(DeliveryPreference), default=DeliveryPreference.HOME_DELIVERY, nullable=False)
    delivery_address = Column(String(255), nullable=False)
    latitude = Column(Float, nullable=False, default=12.9716)
    longitude = Column(Float, nullable=False, default=77.5946)
    target_budget = Column(Float, nullable=True)
    need_by = Column(DateTime, nullable=False)
    status = Column(Enum(RFQStatus), default=RFQStatus.BROADCASTING, nullable=False)
    accepted_quotation_id = Column(String(36), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=False)

