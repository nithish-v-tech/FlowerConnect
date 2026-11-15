import pytest
from app.core.database import AsyncSessionLocal
from app.core.init_db import init_database
from app.api.v1.rfq import create_rfq, list_rfqs, get_rfq
from app.api.v1.quotations import submit_quotation, get_quotations_for_rfq, accept_quotation
from app.schemas.rfq import RFQCreate
from app.schemas.quotation import QuotationCreate, QuotationAcceptRequest
from app.models.rfq import DeliveryPreference, RFQStatus
from app.models.quotation import QuotationStatus
from app.models.order import Order, PaymentStatus, OrderStatus
from sqlalchemy import select

@pytest.mark.anyio
async def test_persistent_rfq_lifecycle_in_database():
    await init_database()
    async with AsyncSessionLocal() as session:
        # 1. Create RFQ
        rfq_payload = RFQCreate(
            customer_id="cust_01",
            customer_name="Pooja Hegde",
            title="100 Fresh Jasmine Garlands",
            flower_type="Jasmine",
            quantity_description="100 meters fresh garlands",
            occasion="Temple Pooja",
            delivery_preference=DeliveryPreference.HOME_DELIVERY,
            delivery_address="Indiranagar, Bengaluru",
            latitude=12.9716,
            longitude=77.5946,
            target_budget=4500.0,
            need_by_hours=4
        )
        created_rfq = await create_rfq(rfq_payload, db=session)
        assert created_rfq.id is not None
        assert created_rfq.status == RFQStatus.BROADCASTING
        rfq_id = created_rfq.id

        # 2. List RFQs from database
        all_rfqs = await list_rfqs(customer_id="cust_01", db=session)
        matching = [r for r in all_rfqs if r.id == rfq_id]
        assert len(matching) == 1
        assert matching[0].flower_type == "Jasmine"

        # 3. Submit Vendor Quotation
        quote_payload = QuotationCreate(
            rfq_id=rfq_id,
            merchant_id="shop_001",
            shop_name="Sri Lakshmi Flower Stall",
            merchant_phone="+91 98450 12345",
            merchant_rating=4.9,
            distance_km=1.2,
            quoted_price=4200.0,
            delivery_fee=50.0,
            prep_time_minutes=30,
            notes="Morning fresh Madurai Jasmine",
            freshness_guarantee="100% genuine farm fresh"
        )
        submitted_quote = await submit_quotation(quote_payload, db=session)
        assert submitted_quote.id is not None
        assert submitted_quote.quoted_price == 4200.0
        assert submitted_quote.status == QuotationStatus.PENDING
        quote_id = submitted_quote.id

        # 4. Fetch Quotations from database
        quotes = await get_quotations_for_rfq(rfq_id, db=session)
        assert len(quotes) >= 1
        assert any(q.id == quote_id for q in quotes)

        # 5. Customer accepts quotation -> Creates persistent Order in DB
        accept_resp = await accept_quotation(QuotationAcceptRequest(
            rfq_id=rfq_id,
            quotation_id=quote_id
        ), db=session)
        assert accept_resp["rfq_status"] == RFQStatus.ACCEPTED.value
        order_id = accept_resp["order_id"]

        # 6. Verify persistent Order record in database
        order_res = await session.execute(select(Order).where(Order.id == order_id))
        order = order_res.scalars().first()
        assert order is not None
        assert order.shop_id == "shop_001"
        assert order.status == OrderStatus.CONFIRMED
        assert order.payment_status == PaymentStatus.PENDING
        assert order.driver_id is None # Unassigned until dispatch

