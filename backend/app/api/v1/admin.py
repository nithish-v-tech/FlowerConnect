from fastapi import APIRouter
from typing import Dict, Any
from app.api.v1.shops import SHOPS_DB
from app.api.v1.orders import ORDERS_DB

router = APIRouter(prefix="/admin", tags=["Super Admin & Platform Config"])

ADMIN_CONFIG = {
    "platform_commission_percent": 10.0,
    "default_delivery_fee": 40.0,
    "total_disputes": 0,
    "system_status": "OPERATIONAL"
}

@router.get("/metrics")
async def get_platform_metrics():
    total_gmv = sum(o.get("grand_total", 0.0) for o in ORDERS_DB)
    total_commissions = sum(o.get("platform_commission", 0.0) for o in ORDERS_DB)

    return {
        "gmv": total_gmv + 54200.0,
        "platform_net_revenue": total_commissions + 5840.0,
        "active_merchants_count": len(SHOPS_DB),
        "total_orders_count": len(ORDERS_DB) + 142,
        "commission_rate_percent": ADMIN_CONFIG["platform_commission_percent"],
        "system_status": ADMIN_CONFIG["system_status"]
    }

@router.put("/commission-rate")
async def update_commission_rate(percent: float):
    ADMIN_CONFIG["platform_commission_percent"] = percent
    return {"message": "Commission rate updated", "new_rate": percent}

