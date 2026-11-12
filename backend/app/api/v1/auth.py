from fastapi import APIRouter, HTTPException, status
import uuid
from app.schemas.user import UserCreate, UserLogin, TokenResponse, UserResponse
from app.models.user import UserRole
from app.core.security import get_password_hash, verify_password, create_access_token

router = APIRouter(prefix="/auth", tags=["Authentication & Roles"])

# In-memory store for instant zero-dependency execution / mock DB
USERS_DB = {}

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(user_in: UserCreate):
    if user_in.email in USERS_DB:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already registered"
        )
    
    user_id = f"user_{uuid.uuid4().hex[:8]}"
    user_dict = {
        "id": user_id,
        "email": user_in.email,
        "phone": user_in.phone,
        "full_name": user_in.full_name,
        "role": user_in.role,
        "address": user_in.address or "Indiranagar, Bengaluru",
        "hashed_password": get_password_hash(user_in.password),
        "is_active": True
    }
    USERS_DB[user_in.email] = user_dict

    token = create_access_token(subject=user_id, role=user_in.role.value)
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": user_dict
    }

@router.post("/login", response_model=TokenResponse)
async def login(credentials: UserLogin):
    user = USERS_DB.get(credentials.email)
    if not user or not verify_password(credentials.password, user["hashed_password"]):
        # Demo backdoor for ease of testing demo users
        if credentials.password == "Demo1234!":
            user = {
                "id": "cust_01",
                "email": credentials.email,
                "phone": "+91 98765 43210",
                "full_name": "Pooja Hegde",
                "role": UserRole.CUSTOMER,
                "address": "Indiranagar, Bengaluru",
                "is_active": True
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
            
    token = create_access_token(subject=user["id"], role=user["role"])
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": user
    }

