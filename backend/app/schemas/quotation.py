from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.models.quotation import QuotationStatus

class QuotationCreate(BaseModel):
    rfq_id: str
    merchant_id: str
    shop_name: str
    merchant_phone: str
    merchant_rating: float = 4.8
    distance_km: float = 1.0
    quoted_price: float
    delivery_fee: float = 35.0
    prep_time_minutes: int = 25
    notes: Optional[str] = "Farm fresh morning cuts"
    freshness_guarantee: Optional[str] = "100% fresh morning harvest"

class QuotationResponse(BaseModel):
    id: str
    rfq_id: str
    merchant_id: str
    shop_name: str
    merchant_phone: str
    merchant_rating: float
    distance_km: float
    quoted_price: float
    delivery_fee: float
    prep_time_minutes: int
    notes: Optional[str]
    freshness_guarantee: str
    status: QuotationStatus
    submitted_at: datetime
    expires_at: datetime

    class Config:
        from_attributes = True

class QuotationAcceptRequest(BaseModel):
    rfq_id: str
    quotation_id: str

