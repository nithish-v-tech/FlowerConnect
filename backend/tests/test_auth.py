import pytest
from app.api.v1.auth import request_otp, verify_otp
from app.schemas.user import OTPRequest, OTPVerifyRequest
from app.models.user import UserRole
from app.core.database import AsyncSessionLocal
from app.core.init_db import init_database
from fastapi import HTTPException

@pytest.mark.anyio
async def test_otp_request_and_login_customer():
    await init_database()
    async with AsyncSessionLocal() as session:
        # Request OTP
        req_resp = await request_otp(OTPRequest(phone="+91 98765 43210"), db=session)
        assert req_resp["status"] == "success"
        otp_code = req_resp["otp_code"]

        # Verify OTP
        verify_resp = await verify_otp(OTPVerifyRequest(
            phone="+91 98765 43210",
            otp=otp_code
        ), db=session)
        assert verify_resp["access_token"] is not None
        assert verify_resp["user"]["role"] == UserRole.CUSTOMER
        assert verify_resp["user"]["full_name"] == "Pooja Hegde"

@pytest.mark.anyio
async def test_otp_reject_admin_self_assignment():
    await init_database()
    async with AsyncSessionLocal() as session:
        with pytest.raises(HTTPException) as excinfo:
            await verify_otp(OTPVerifyRequest(
                phone="+91 97777 66666",
                otp="123456",
                full_name="Attacker",
                role=UserRole.ADMIN
            ), db=session)
        assert excinfo.value.status_code == 403
        assert "Admin role cannot be self-assigned" in excinfo.value.detail

@pytest.mark.anyio
async def test_otp_new_vendor_pending_approval():
    await init_database()
    async with AsyncSessionLocal() as session:
        verify_resp = await verify_otp(OTPVerifyRequest(
            phone="+91 98888 77777",
            otp="123456",
            full_name="Radha Krishna Florals",
            role=UserRole.FLOWER_MERCHANT
        ), db=session)
        assert verify_resp["user"]["role"] == UserRole.FLOWER_MERCHANT
        assert verify_resp["user"]["is_vendor_approved"] is False
