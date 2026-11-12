from datetime import datetime
from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, ForeignKey
from app.core.database import Base

class DeliveryPartner(Base):
    __tablename__ = "delivery_partners"

    id = Column(String(36), primary_key=True, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    vehicle_type = Column(String(50), default="Two-Wheeler Motorcycle")
    vehicle_number = Column(String(30), default="KA-03-EX-9921")
    is_online = Column(Boolean, default=True)
    current_lat = Column(Float, default=12.9716)
    current_lng = Column(Float, default=77.5946)
    rating = Column(Float, default=4.9)
    total_deliveries = Column(Integer, default=48)
    wallet_balance = Column(Float, default=680.0)
    created_at = Column(DateTime, default=datetime.utcnow)

