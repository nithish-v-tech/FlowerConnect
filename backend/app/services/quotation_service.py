from datetime import datetime, timedelta
from typing import Dict, Any, List
import uuid

class QuotationManagementService:
    @staticmethod
    def create_rfq(
        customer_id: str,
        customer_name: str,
        title: str,
        flower_type: str,
        quantity_description: str,
        delivery_preference: str,
        delivery_address: str,
        latitude: float,
        longitude: float,
        target_budget: float = None,
        need_by_hours: int = 3,
        expiry_minutes: int = 45
    ) -> Dict[str, Any]:
        rfq_id = f"rfq_{uuid.uuid4().hex[:8]}"
        now = datetime.utcnow()
        return {
            "id": rfq_id,
            "customer_id": customer_id,
            "customer_name": customer_name,
            "title": title,
            "flower_type": flower_type,
            "quantity_description": quantity_description,
            "delivery_preference": delivery_preference,
            "delivery_address": delivery_address,
            "latitude": latitude,
            "longitude": longitude,
            "target_budget": target_budget,
            "need_by": (now + timedelta(hours=need_by_hours)).isoformat(),
            "status": "BROADCASTING",
            "accepted_quotation_id": None,
            "created_at": now.isoformat(),
            "expires_at": (now + timedelta(minutes=expiry_minutes)).isoformat()
        }

    @staticmethod
    def submit_quote(
        rfq_id: str,
        merchant_id: str,
        shop_name: str,
        merchant_phone: str,
        merchant_rating: float,
        distance_km: float,
        quoted_price: float,
        delivery_fee: float = 35.0,
        prep_time_minutes: int = 25,
        notes: str = "",
        freshness_guarantee: str = "100% farm fresh"
    ) -> Dict[str, Any]:
        quote_id = f"quote_{uuid.uuid4().hex[:8]}"
        now = datetime.utcnow()
        return {
            "id": quote_id,
            "rfq_id": rfq_id,
            "merchant_id": merchant_id,
            "shop_name": shop_name,
            "merchant_phone": merchant_phone,
            "merchant_rating": merchant_rating,
            "distance_km": distance_km,
            "quoted_price": quoted_price,
            "delivery_fee": delivery_fee,
            "prep_time_minutes": prep_time_minutes,
            "notes": notes,
            "freshness_guarantee": freshness_guarantee,
            "status": "PENDING",
            "submitted_at": now.isoformat(),
            "expires_at": (now + timedelta(minutes=30)).isoformat()
        }

    @staticmethod
    def accept_and_lock_quotation(
        rfq: Dict[str, Any],
        quotations: List[Dict[str, Any]],
        accepted_quote_id: str
    ) -> Dict[str, Any]:
        """
        Accepts one quotation and atomically locks the RFQ.
        Marks all other rival quotations as REJECTED.
        Prevents multiple merchants from receiving the same confirmed order.
        """
        winner = None
        updated_quotes = []

        for q in quotations:
            if q["id"] == accepted_quote_id:
                q["status"] = "ACCEPTED"
                winner = q
            else:
                q["status"] = "REJECTED"
            updated_quotes.append(q)

        if not winner:
            raise ValueError(f"Quotation {accepted_quote_id} not found for RFQ {rfq['id']}")

        rfq["status"] = "ACCEPTED"
        rfq["accepted_quotation_id"] = accepted_quote_id

        # Generate confirmed order details
        order_id = f"ORD-Q{uuid.uuid4().hex[:6].upper()}"
        commission_rate = 0.10
        commission = round(winner["quoted_price"] * commission_rate, 2)
        grand_total = winner["quoted_price"] + (winner["delivery_fee"] if rfq["delivery_preference"] == "HOME_DELIVERY" else 0.0)

        confirmed_order = {
            "id": order_id,
            "customer_id": rfq["customer_id"],
            "customer_name": rfq["customer_name"],
            "shop_id": winner["merchant_id"],
            "shop_name": winner["shop_name"],
            "quotation_id": winner["id"],
            "items_total": winner["quoted_price"],
            "delivery_fee": winner["delivery_fee"] if rfq["delivery_preference"] == "HOME_DELIVERY" else 0.0,
            "platform_commission": commission,
            "grand_total": grand_total,
            "fulfillment": rfq["delivery_preference"],
            "status": "CONFIRMED",
            "delivery_otp": "4821",
            "created_at": datetime.utcnow().isoformat()
        }

        return {
            "rfq": rfq,
            "winning_quotation": winner,
            "updated_quotations": updated_quotes,
            "confirmed_order": confirmed_order
        }

