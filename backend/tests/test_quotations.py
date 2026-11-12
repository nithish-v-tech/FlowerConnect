import pytest
from app.services.quotation_service import QuotationManagementService

def test_rfq_creation_and_expiry():
    rfq = QuotationManagementService.create_rfq(
        customer_id="cust_test",
        customer_name="Pooja Test",
        title="100 Carnations",
        flower_type="Carnations",
        quantity_description="100 pink stems",
        delivery_preference="HOME_DELIVERY",
        delivery_address="Indiranagar, Bangalore",
        latitude=12.9716,
        longitude=77.5946,
        target_budget=2500.0,
        need_by_hours=2,
        expiry_minutes=30
    )

    assert rfq["status"] == "BROADCASTING"
    assert rfq["customer_id"] == "cust_test"
    assert rfq["accepted_quotation_id"] is None
    assert "expires_at" in rfq

def test_quotation_single_winner_lock_and_rival_rejection():
    rfq = QuotationManagementService.create_rfq(
        customer_id="cust_test",
        customer_name="Pooja Test",
        title="50 Roses",
        flower_type="Red Roses",
        quantity_description="50 stems",
        delivery_preference="HOME_DELIVERY",
        delivery_address="Indiranagar, Bangalore",
        latitude=12.9716,
        longitude=77.5946
    )

    quote1 = QuotationManagementService.submit_quote(
        rfq_id=rfq["id"],
        merchant_id="shop_01",
        shop_name="Shop 1",
        merchant_phone="+91 99999 11111",
        merchant_rating=4.8,
        distance_km=1.0,
        quoted_price=1800.0,
        delivery_fee=30.0
    )

    quote2 = QuotationManagementService.submit_quote(
        rfq_id=rfq["id"],
        merchant_id="shop_02",
        shop_name="Shop 2",
        merchant_phone="+91 99999 22222",
        merchant_rating=4.9,
        distance_km=2.0,
        quoted_price=2100.0,
        delivery_fee=40.0
    )

    all_quotes = [quote1, quote2]

    # Customer accepts quote 1
    result = QuotationManagementService.accept_and_lock_quotation(
        rfq=rfq,
        quotations=all_quotes,
        accepted_quote_id=quote1["id"]
    )

    # 1. Winning quote must be ACCEPTED
    assert result["winning_quotation"]["id"] == quote1["id"]
    assert result["winning_quotation"]["status"] == "ACCEPTED"

    # 2. Rival quote must be REJECTED (locking mechanism)
    competing_quote = next(q for q in result["updated_quotations"] if q["id"] == quote2["id"])
    assert competing_quote["status"] == "REJECTED"

    # 3. RFQ state must be locked as ACCEPTED
    assert result["rfq"]["status"] == "ACCEPTED"
    assert result["rfq"]["accepted_quotation_id"] == quote1["id"]

    # 4. Confirmed order must be generated
    confirmed_order = result["confirmed_order"]
    assert confirmed_order["shop_id"] == "shop_01"
    assert confirmed_order["status"] == "CONFIRMED"
    assert confirmed_order["items_total"] == 1800.0
    assert confirmed_order["platform_commission"] == 180.0 # 10%
    assert confirmed_order["grand_total"] == 1830.0 # 1800 + 30 delivery

