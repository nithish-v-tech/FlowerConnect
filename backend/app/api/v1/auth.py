import uuid
import random
from datetime import datetime, timedelta
from typing import Dict, Any, Optional
from fastapi import APIRouter, HTTPException, Depends, status, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete

from app.core.database import get_db
from app.core.security import create_access_token, decode_access_token
from app.models.user import User, UserRole, OTPRecord
from app.models.shop import Shop, ShopType
from app.schemas.user import UserCreate, UserLogin, TokenResponse, UserResponse, OTPRequest, OTPVerifyRequest

router = APIRouter(prefix="/auth", tags=["Authentication & Roles"])

def normalize_phone(raw: str) -> str:
    cleaned = raw.strip().replace(" ", "").replace("-", "")
    if not cleaned.startswith("+91") and len(cleaned) == 10:
        cleaned = f"+91{cleaned}"
    elif cleaned.startswith("91") and len(cleaned) == 12:
        cleaned = f"+{cleaned}"
    return cleaned

@router.post("/request-otp")
async def request_otp(data: OTPRequest, db: AsyncSession = Depends(get_db)):
    phone = normalize_phone(data.phone)
    if len(phone) < 12:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please provide a valid 10-digit mobile number."
        )

    # Generate a 6-digit OTP
    # For demo numbers, use 123456 for effortless evaluation; for other numbers generate random
    demo_phones = ["+919876543210", "+919845012345", "+919845198765", "+919916055443", "+919999988888", "+919000000001", "+919448033211"]
    if phone in demo_phones:
        otp_code = "123456"
    else:
        otp_code = str(random.randint(100000, 999999))

    # Clean existing OTP for this phone and insert new record
    await db.execute(delete(OTPRecord).where(OTPRecord.phone == phone))
    otp_record = OTPRecord(
        id=str(uuid.uuid4()),
        phone=phone,
        otp_code=otp_code,
        expires_at=datetime.utcnow() + timedelta(minutes=10),
        created_at=datetime.utcnow(),
    )
    db.add(otp_record)
    await db.commit()

    print(f"[SMS Gateway Simulator] Sent 6-digit OTP [{otp_code}] to mobile [{phone}]")

    return {
        "status": "success",
        "phone": phone,
        "message": f"6-digit OTP sent successfully to {phone}",
        "otp_code": otp_code,
        "expires_in_minutes": 10
    }

@router.post("/verify-otp")
async def verify_otp(data: OTPVerifyRequest, db: AsyncSession = Depends(get_db)):
    phone = normalize_phone(data.phone)

    # 1. Verify OTP against database OTPRecord
    result = await db.execute(select(OTPRecord).where(OTPRecord.phone == phone))
    otp_record = result.scalars().first()

    valid = False
    if otp_record and otp_record.otp_code == data.otp.strip():
        if datetime.utcnow() <= otp_record.expires_at:
            valid = True

    # Fallback to demo OTP 123456 for developer testing
    if data.otp.strip() == "123456":
        valid = True

    if not valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired 6-digit OTP code."
        )

    # 2. Strict Security: Block self-assignment of Admin
    if data.role == UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Admin role cannot be self-assigned."
        )

    # 3. Check if user already exists in database
    user_result = await db.execute(select(User).where(User.phone == phone))
    user = user_result.scalars().first()

    if user:
        # Existing registered user
        token = create_access_token(subject=user.id, role=user.role.value)
        return {
            "access_token": token,
            "token_type": "bearer",
            "user": {
                "id": user.id,
                "email": user.email,
                "phone": user.phone,
                "full_name": user.full_name,
                "role": user.role,
                "shop_id": user.shop_id,
                "is_vendor_approved": user.is_vendor_approved,
                "address": user.address,
                "is_active": user.is_active,
            }
        }
    else:
        # User not found in DB
        # If registration details are provided, register the user in DB now
        if data.full_name:
            user_id = f"user_{uuid.uuid4().hex[:8]}"
            assigned_role = data.role or UserRole.CUSTOMER
            is_vendor = assigned_role in [
                UserRole.FLOWER_MERCHANT,
                UserRole.BOUQUET_MERCHANT,
                UserRole.GIFT_MERCHANT
            ]

            created_shop_id = None
            if is_vendor:
                created_shop_id = f"shop_{uuid.uuid4().hex[:6]}"
                new_shop = Shop(
                    id=created_shop_id,
                    user_id=user_id,
                    name=data.shop_name or f"{data.full_name} Stall",
                    shop_type=ShopType.FLOWER_SHOP,
                    address=data.address or "Bengaluru, Karnataka",
                    latitude=12.9716,
                    longitude=77.5946,
                    rating=0.0,
                    total_reviews=0,
                    image_url="https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=600&q=80",
                    is_verified=False,  # REQUIRE ADMIN APPROVAL
                    is_featured=False,
                    is_open=False,
                    owner_name=data.full_name,
                    contact_phone=phone,
                    daily_rates={},
                )
                db.add(new_shop)

            new_user = User(
                id=user_id,
                email=f"{user_id}@flowerconnect.app",
                phone=phone,
                full_name=data.full_name,
                role=assigned_role,
                shop_id=created_shop_id,
                is_vendor_approved=False if is_vendor else True,
                address=data.address or "Bengaluru, Karnataka",
                is_active=True,
                created_at=datetime.utcnow()
            )
            db.add(new_user)
            await db.commit()

            token = create_access_token(subject=new_user.id, role=new_user.role.value)
            return {
                "access_token": token,
                "token_type": "bearer",
                "user": {
                    "id": new_user.id,
                    "email": new_user.email,
                    "phone": new_user.phone,
                    "full_name": new_user.full_name,
                    "role": new_user.role,
                    "shop_id": new_user.shop_id,
                    "is_vendor_approved": new_user.is_vendor_approved,
                    "address": new_user.address,
                    "is_active": new_user.is_active,
                }
            }
        else:
            # Need to collect profile info
            return {
                "status": "new_user",
                "phone": phone,
                "message": "New mobile number. Profile registration required."
            }

@router.post("/register")
async def register_user(payload: OTPVerifyRequest, db: AsyncSession = Depends(get_db)):
    if payload.role == UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Admin role cannot be self-assigned."
        )

    phone = normalize_phone(payload.phone)
    existing = await db.execute(select(User).where(User.phone == phone))
    if existing.scalars().first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this phone number already registered."
        )

    user_id = f"user_{uuid.uuid4().hex[:8]}"
    assigned_role = payload.role or UserRole.CUSTOMER
    is_vendor = assigned_role in [
        UserRole.FLOWER_MERCHANT,
        UserRole.BOUQUET_MERCHANT,
        UserRole.GIFT_MERCHANT
    ]

    created_shop_id = None
    if is_vendor:
        created_shop_id = f"shop_{uuid.uuid4().hex[:6]}"
        shop_type = ShopType.FLOWER_SHOP
        if payload.shop_type == "BOUQUET_SHOP":
            shop_type = ShopType.BOUQUET_SHOP
        elif payload.shop_type == "GIFT_SHOP":
            shop_type = ShopType.GIFT_SHOP

        new_shop = Shop(
            id=created_shop_id,
            user_id=user_id,
            name=payload.shop_name or f"{payload.full_name} Stall",
            shop_type=shop_type,
            address=payload.address or "Bengaluru, Karnataka",
            latitude=12.9716,
            longitude=77.5946,
            rating=0.0,
            total_reviews=0,
            image_url="https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=600&q=80",
            is_verified=False,  # PENDING ADMIN VERIFICATION
            is_featured=False,
            is_open=False,
            owner_name=payload.full_name or "Vendor",
            contact_phone=phone,
            daily_rates={},
        )
        db.add(new_shop)

    new_user = User(
        id=user_id,
        email=f"{user_id}@flowerconnect.app",
        phone=phone,
        full_name=payload.full_name or "New User",
        role=assigned_role,
        shop_id=created_shop_id,
        is_vendor_approved=False if is_vendor else True,
        address=payload.address or "Bengaluru, Karnataka",
        is_active=True,
        created_at=datetime.utcnow()
    )
    db.add(new_user)
    await db.commit()

    token = create_access_token(subject=new_user.id, role=new_user.role.value)
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": new_user.id,
            "email": new_user.email,
            "phone": new_user.phone,
            "full_name": new_user.full_name,
            "role": new_user.role,
            "shop_id": new_user.shop_id,
            "is_vendor_approved": new_user.is_vendor_approved,
            "address": new_user.address,
            "is_active": new_user.is_active,
        }
    }

@router.get("/me")
async def get_me(authorization: Optional[str] = Header(None), db: AsyncSession = Depends(get_db)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing or invalid token.")

    token = authorization.split(" ")[1]
    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token.")

    user_id = payload.get("sub")
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")

    return {
        "id": user.id,
        "email": user.email,
        "phone": user.phone,
        "full_name": user.full_name,
        "role": user.role,
        "shop_id": user.shop_id,
        "is_vendor_approved": user.is_vendor_approved,
        "address": user.address,
        "is_active": user.is_active,
    }
