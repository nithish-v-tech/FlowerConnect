from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from app.models.rfq import DeliveryPreference, RFQStatus

class RFQCreate(BaseModel):
    customer_id: str
    customer_name: str
    title: str
    flower_type: str
    quantity_description: str
    occasion: Optional[str] = None
    delivery_preference: DeliveryPreference = DeliveryPreference.HOME_DELIVERY
    delivery_address: str
    latitude: float = 12.9716
    longitude: float = 77.5946
    target_budget: Optional[float] = None
    need_by_hours: int = 3

class RFQResponse(BaseModel):
    id: str
    customer_id: str
    customer_name: str
    title: str
    flower_type: str
    quantity_description: str
    occasion: Optional[str]
    delivery_preference: DeliveryPreference
    delivery_address: str
    latitude: float
    longitude: float
    target_budget: Optional[float]
    need_by: datetime
    status: RFQStatus
    accepted_quotation_id: Optional[str]
    created_at: datetime
    expires_at: datetime

    class Config:
        from_attributes = True

