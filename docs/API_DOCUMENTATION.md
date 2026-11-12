# FlowerConnect REST API Specification

**Base URL**: `http://localhost:8000/api/v1`  
**Interactive Swagger UI**: `http://localhost:8000/docs`  
**ReDoc**: `http://localhost:8000/redoc`

---

## 1. Authentication (`/api/v1/auth`)

### `POST /auth/register`
Register a new user (Customer, Merchant, Delivery Partner, Admin).
```json
{
  "email": "customer@example.com",
  "phone": "+91 98765 43210",
  "full_name": "Pooja Hegde",
  "password": "Password123!",
  "role": "CUSTOMER",
  "address": "Flat 402, Oakwood Heights, Indiranagar, Bengaluru"
}
```

### `POST /auth/login`
Authenticate and obtain JWT access token.
```json
{
  "email": "customer@example.com",
  "password": "Password123!"
}
```

---

## 2. Shops & Wholesalers (`/api/v1/shops`)

### `GET /shops`
Query nearby flower stalls, bouquet boutiques, and gift shops.
- **Parameters**: `shop_type`, `lat`, `lng`, `radius_km`

### `GET /shops/{shop_id}`
Get shop details, live rating, owner details, and today's flower market rates.

### `PUT /shops/{shop_id}/daily-rates`
Merchant endpoint to publish daily morning wholesale mandi flower rates.
```json
{
  "rates": {
    "Fresh Jasmine (Madurai Malli)": 480.0,
    "Dutch Red Roses (20 stems)": 280.0,
    "Yellow Marigold (Genda kg)": 120.0
  }
}
```

---

## 3. Dynamic Price Quotations (`/api/v1/rfq` & `/api/v1/quotations`)

### `POST /rfq`
Customer broadcasts a customized flower or event requirement.
```json
{
  "customer_id": "cust_01",
  "customer_name": "Pooja Hegde",
  "title": "50 Red Roses for Wedding Anniversary",
  "flower_type": "Dutch Red Roses & Lilies",
  "quantity_description": "50 long-stem roses with foliage",
  "occasion": "Wedding Anniversary",
  "delivery_preference": "HOME_DELIVERY",
  "delivery_address": "Indiranagar, Bengaluru",
  "latitude": 12.9716,
  "longitude": 77.5946,
  "target_budget": 2000.0,
  "need_by_hours": 3
}
```

### `POST /quotations/submit`
Merchant submits a price quotation for an active RFQ.
```json
{
  "rfq_id": "rfq_1001",
  "merchant_id": "shop_001",
  "shop_name": "Sri Lakshmi Flower Stall",
  "merchant_phone": "+91 98450 12345",
  "merchant_rating": 4.8,
  "distance_km": 0.8,
  "quoted_price": 1850.0,
  "delivery_fee": 30.0,
  "prep_time_minutes": 25,
  "notes": "Morning fresh Ooty harvest roses with moisture sponge wrapper.",
  "freshness_guarantee": "Guaranteed 5-day freshness or free replacement"
}
```

### `GET /quotations/rfq/{rfq_id}`
Customer retrieves and compares all competing bids for their RFQ.

### `POST /quotations/accept`
Customer accepts a single quotation.
```json
{
  "rfq_id": "rfq_1001",
  "quotation_id": "quote_1"
}
```
**Effect**: Locks the accepted quote, marks rival quotes as `REJECTED`, and creates a confirmed `Order`.

---

## 4. Customer Orders & Fulfillment (`/api/v1/orders`)

### `POST /orders`
Direct catalogue checkout.
```json
{
  "customer_id": "cust_01",
  "customer_name": "Pooja Hegde",
  "customer_phone": "+91 98765 43210",
  "shop_id": "shop_002",
  "shop_name": "Petals & Blooms Studio",
  "items": [
    {
      "product_id": "prod_001",
      "product_name": "Midnight Crimson - 24 Red Roses",
      "unit_price": 899.0,
      "quantity": 1,
      "unit": "Bouquet"
    }
  ],
  "fulfillment": "HOME_DELIVERY",
  "payment_method": "UPI",
  "delivery_address": "Indiranagar, Bengaluru",
  "is_surprise_delivery": true,
  "surprise_recipient_name": "Rahul Hegde",
  "surprise_note": "Happy 10th Anniversary!"
}
```

### `PUT /orders/{order_id}/status`
Transition order through lifecycle (`CONFIRMED`, `PREPARING`, `READY_FOR_PICKUP`, `OUT_FOR_DELIVERY`, `DELIVERED`).

### `POST /orders/verify-delivery-otp`
Partner submits 4-digit code to complete delivery and release funds.
```json
{
  "order_id": "ORD-98421",
  "otp": "4821"
}
```

---

## 5. Delivery Partner (`/api/v1/delivery`)

- `GET /delivery/status`: Driver availability & wallet balance.
- `PUT /delivery/toggle-online`: Duty toggle.
- `GET /delivery/active-trips`: Active trips assigned to driver.

---

## 6. Super Admin (`/api/v1/admin`)

- `GET /admin/metrics`: Platform GMV, net revenue, merchant count.
- `PUT /admin/commission-rate`: Update platform commission percentage.

