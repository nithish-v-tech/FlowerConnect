import enum
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Enum, Integer
from app.core.database import Base

class UserRole(str, enum.Enum):
    CUSTOMER = "CUSTOMER"
    FLOWER_MERCHANT = "FLOWER_MERCHANT"
    BOUQUET_MERCHANT = "BOUQUET_MERCHANT"
    GIFT_MERCHANT = "GIFT_MERCHANT"
    DELIVERY_PARTNER = "DELIVERY_PARTNER"
    ADMIN = "ADMIN"

class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, index=True)
    email = Column(String(120), unique=True, index=True, nullable=False)
    phone = Column(String(20), unique=True, index=True, nullable=False)
    full_name = Column(String(100), nullable=False)
    hashed_password = Column(String(255), nullable=True)
    role = Column(Enum(UserRole), default=UserRole.CUSTOMER, nullable=False)
    shop_id = Column(String(36), nullable=True)
    is_vendor_approved = Column(Boolean, default=True, nullable=True)
    address = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class OTPRecord(Base):
    __tablename__ = "otp_records"

    id = Column(String(36), primary_key=True, index=True)
    phone = Column(String(20), unique=True, index=True, nullable=False)
    otp_code = Column(String(6), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
