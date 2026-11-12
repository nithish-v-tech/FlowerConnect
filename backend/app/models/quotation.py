import enum
from datetime import datetime
from sqlalchemy import Column, String, Float, Integer, DateTime, Enum, ForeignKey
from app.core.database import Base

class QuotationStatus(str, enum.Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    REJECTED = "REJECTED"
    EXPIRED = "EXPIRED"

class Quotation(Base):
    __tablename__ = "quotations"

    id = Column(String(36), primary_key=True, index=True)
    rfq_id = Column(String(36), ForeignKey("rfq_requests.id"), nullable=False)
    merchant_id = Column(String(36), ForeignKey("shops.id"), nullable=False)
    shop_name = Column(String(120), nullable=False)
    merchant_phone = Column(String(20), nullable=False)
    merchant_rating = Column(Float, default=4.8)
    distance_km = Column(Float, nullable=False, default=1.0)
    quoted_price = Column(Float, nullable=False)
    delivery_fee = Column(Float, default=35.0)
    prep_time_minutes = Column(Integer, default=25)
    notes = Column(String(500), nullable=True)
    freshness_guarantee = Column(String(200), default="100% morning farm fresh")
    status = Column(Enum(QuotationStatus), default=QuotationStatus.PENDING, nullable=False)
    submitted_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=False)

