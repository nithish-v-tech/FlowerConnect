from datetime import datetime
from sqlalchemy import Column, String, Float, Integer, DateTime, ForeignKey
from app.core.database import Base

class PlatformCommission(Base):
    __tablename__ = "platform_commissions"

    id = Column(String(36), primary_key=True, index=True)
    order_id = Column(String(36), ForeignKey("orders.id"), nullable=False)
    gross_amount = Column(Float, nullable=False)
    commission_rate = Column(Float, nullable=False, default=0.10)
    platform_fee = Column(Float, nullable=False)
    merchant_payout = Column(Float, nullable=False)
    delivery_payout = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class Review(Base):
    __tablename__ = "reviews"

    id = Column(String(36), primary_key=True, index=True)
    order_id = Column(String(36), ForeignKey("orders.id"), nullable=False)
    customer_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    merchant_id = Column(String(36), ForeignKey("shops.id"), nullable=False)
    rating = Column(Integer, nullable=False)
    comment = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

