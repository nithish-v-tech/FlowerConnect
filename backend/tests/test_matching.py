import pytest
from app.services.matching_engine import FairMerchantMatchingEngine

def test_haversine_distance_calculation():
    # Indiranagar to Koramangala (~5 km)
    lat1, lon1 = 12.9716, 77.5946
    lat2, lon2 = 12.9352, 77.6245
    dist = FairMerchantMatchingEngine.calculate_haversine_distance(lat1, lon1, lat2, lon2)
    assert 4.0 <= dist <= 6.0

def test_fair_merchant_matching_radius_and_scoring():
    customer_lat, customer_lng = 12.9716, 77.5946
    merchants = [
        {
            "id": "shop_01",
            "name": "Roadside Fresh Stall",
            "latitude": 12.9730,
            "longitude": 77.5960,
            "rating": 4.8,
            "is_open": True,
            "shop_type": "FLOWER_SHOP"
        },
        {
            "id": "shop_02",
            "name": "Luxury Florist Koramangala",
            "latitude": 12.9352,
            "longitude": 77.6245,
            "rating": 4.9,
            "is_open": True,
            "shop_type": "BOUQUET_SHOP"
        },
        {
            "id": "shop_03",
            "name": "Distant Stall (Too far)",
            "latitude": 13.1500,
            "longitude": 77.8000,
            "rating": 4.5,
            "is_open": True,
            "shop_type": "FLOWER_SHOP"
        }
    ]

    matched = FairMerchantMatchingEngine.match_nearby_merchants(
        customer_lat=customer_lat,
        customer_lng=customer_lng,
        merchants=merchants,
        max_radius_km=6.0
    )

    # Distant merchant (> 15km) must be filtered out
    assert len(matched) == 2
    merchant_ids = [m["merchant_id"] for m in matched]
    assert "shop_01" in merchant_ids
    assert "shop_02" in merchant_ids
    assert "shop_03" not in merchant_ids

    # Nearest merchant shop_01 should receive higher composite match score
    assert matched[0]["merchant_id"] == "shop_01"
    assert matched[0]["composite_match_score"] > matched[1]["composite_match_score"]

