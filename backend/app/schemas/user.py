from pydantic import BaseModel
from typing import Optional
from app.models.user import UserRole

class UserBase(BaseModel):
    email: Optional[str] = None
    phone: str
    full_name: str
    role: UserRole = UserRole.CUSTOMER
    address: Optional[str] = None
    shop_id: Optional[str] = None
    is_vendor_approved: Optional[bool] = None

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class OTPRequest(BaseModel):
    phone: str

class OTPVerifyRequest(BaseModel):
    phone: str
    otp: str
    full_name: Optional[str] = None
    role: Optional[UserRole] = None
    shop_name: Optional[str] = None
    shop_type: Optional[str] = None
    address: Optional[str] = None

class UserResponse(UserBase):
    id: str
    is_active: bool

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
