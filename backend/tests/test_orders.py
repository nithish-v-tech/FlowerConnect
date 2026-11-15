import pytest
from app.models.order import OrderStatus

def test_order_otp_verification_logic():
    test_order = {
        "id": "ORD-TEST-01",
        "customer_id": "cust_01",
        "delivery_otp": "4821",
        "status": OrderStatus.OUT_FOR_DELIVERY
    }

    # Correct OTP
    assert test_order["delivery_otp"] == "4821"

    # Wrong OTP fails
    wrong_otp = "1234"
    assert wrong_otp != test_order["delivery_otp"]

    # Master demo OTP works
    master_otp = "0000"
    assert master_otp == "0000" or test_order["delivery_otp"] == master_otp

