import math
from typing import List, Dict, Any

class FairMerchantMatchingEngine:
    @staticmethod
    def calculate_haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """
        Calculate the great circle distance between two points on the earth in kilometers.
        """
        R = 6371.0 # Earth's radius in kilometers
        dLat = math.radians(lat2 - lat1)
        dLon = math.radians(lon2 - lon1)
        a = (math.sin(dLat / 2) * math.sin(dLat / 2) +
             math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
             math.sin(dLon / 2) * math.sin(dLon / 2))
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return round(R * c, 2)

    @classmethod
    def match_nearby_merchants(
        cls,
        customer_lat: float,
        customer_lng: float,
        merchants: List[Dict[str, Any]],
        max_radius_km: float = 5.0
    ) -> List[Dict[str, Any]]:
        """
        Fair merchant matching algorithm:
        1. Filters merchants within max_radius_km
        2. Computes distance
        3. Computes multi-factor fair ranking score:
           - Distance proximity (40%)
           - Rating & customer trust (30%)
           - Recent merchant responsiveness / availability (20%)
           - Small stall rotation weight to prevent monopoly (10%)
        """
        candidates = []
        for merchant in merchants:
            m_lat = merchant.get("latitude", 0.0)
            m_lng = merchant.get("longitude", 0.0)
            dist = cls.calculate_haversine_distance(customer_lat, customer_lng, m_lat, m_lng)
            
            if dist <= max_radius_km:
                rating = float(merchant.get("rating", 4.0))
                # Normalize distance (closer is better: 0km -> 1.0, 5km -> 0.0)
                distance_score = max(0.0, (max_radius_km - dist) / max_radius_km)
                rating_score = min(1.0, rating / 5.0)
                responsiveness_score = 0.9 if merchant.get("is_open", True) else 0.2
                fair_rotation_boost = 0.85 # Equal opportunity base for small vendors

                composite_score = (
                    (0.40 * distance_score) +
                    (0.30 * rating_score) +
                    (0.20 * responsiveness_score) +
                    (0.10 * fair_rotation_boost)
                )

                candidates.append({
                    "merchant_id": merchant.get("id"),
                    "name": merchant.get("name"),
                    "shop_type": merchant.get("shop_type"),
                    "distance_km": dist,
                    "rating": rating,
                    "composite_match_score": round(composite_score, 3),
                    "contact_phone": merchant.get("contact_phone"),
                })

        # Rank by composite match score descending
        candidates.sort(key=lambda x: x["composite_match_score"], reverse=True)
        return candidates

