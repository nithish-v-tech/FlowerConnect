# FlowerConnect Architecture Specification

## 1. System Overview

**FlowerConnect** is an on-demand hyperlocal marketplace designed to connect consumers with neighborhood flower vendors, small roadside flower stalls, boutique florist studios, and gift shops.

The platform combines two distinct fulfillment paradigms:
1. **Instant Catalogue Ordering**: Browsing nearby shops, choosing flowers or gifts, and placing direct pickup or delivery orders.
2. **Dynamic Price Quotation System (RFQ)**: A customer broadcasts a custom flower requirement or event order. The system matches nearby merchants within a 5 km radius, who submit competing price quotations. The customer compares quotes and accepts one, automatically locking the winning quote and expiring competing quotes.

---

## 2. Technology Stack

- **Mobile Application**: Flutter 3.47+ (Dart 3.13+)
- **State Management**: Riverpod 3 (NotifierProvider & StateNotifier)
- **Backend Architecture**: Clean Architecture (Domain, Data, Presentation layers)
- **Backend Framework**: Python 3.11+ / FastAPI
- **Relational Database**: PostgreSQL 16 with async SQLAlchemy 2.0 ORM & Alembic migrations
- **Authentication**: JWT Bearer Tokens with Firebase Auth bridge support
- **Fair Matching Engine**: Haversine Geolocation Matrix with anti-monopoly fair distribution weighting
- **Containerization**: Docker & Docker Compose

---

## 3. High-Level Architecture Diagram

```mermaid
graph TD
    subgraph Client ["Flutter Mobile Client (Android / iOS / Web)"]
        UI["Presentation Layer (Screens & Reusable Widgets)"]
        State["State Management (Riverpod Notifiers)"]
        DataRepo["Data Repository & HTTP Client"]
        UI --> State
        State --> DataRepo
    end

    subgraph Gateway ["FastAPI Gateway & Routers"]
        AuthRouter["/api/v1/auth"]
        ShopsRouter["/api/v1/shops"]
        ProductsRouter["/api/v1/products"]
        RFQRouter["/api/v1/rfq"]
        QuotesRouter["/api/v1/quotations"]
        OrdersRouter["/api/v1/orders"]
        DeliveryRouter["/api/v1/delivery"]
        AdminRouter["/api/v1/admin"]
    end

    subgraph CoreEngine ["Services & Business Logic"]
        Matching["Fair Merchant Matching Engine"]
        QuotationMgr["Quotation Single-Winner Lock Engine"]
        CommissionMgr["Commission & Payout Ledger"]
    end

    subgraph Persistence ["Storage & External Providers"]
        Postgres[("PostgreSQL 16 Database")]
        FCM["Firebase Cloud Messaging (FCM Push)"]
        GMaps["Google Maps / Geolocation API"]
    end

    DataRepo <-->|REST API JSON| Gateway
    Gateway --> CoreEngine
    CoreEngine --> Postgres
    CoreEngine -.-> FCM
    CoreEngine -.-> GMaps
```

---

## 4. Dynamic Price Quotation Workflow

```mermaid
sequenceDiagram
    autonumber
    actor C as Customer
    participant App as Mobile App
    participant API as FastAPI Backend
    participant Matcher as Fair Matching Engine
    actor M as Nearby Merchants

    C->>App: Enter Requirement (Flowers, Qty, Budget, Window, Delivery/Pickup)
    App->>API: POST /api/v1/rfq
    API->>Matcher: Calculate nearby florists within radius
    Matcher-->>M: Push Broadcast Alert
    M->>API: POST /api/v1/quotations/submit (Offer price, Prep time, Freshness guarantee)
    API-->>App: Push Real-Time Quotes
    C->>App: Compare Quotes (Sort by Price, Distance, Rating, Prep Time)
    C->>API: POST /api/v1/quotations/accept
    API->>API: Lock winning quotation
    API->>API: Expire all rival quotes (Prevent duplicate orders)
    API->>API: Create confirmed Order with OTP
    API-->>App: Navigate to Live Order Tracking
```

---

## 5. Security & Privacy Guarantees

1. **Information Masking**:
   - Customer phone numbers and exact delivery addresses are **hidden** from bidding merchants during the RFQ phase.
   - Only approximate customer distance (e.g., "1.2 km away in Indiranagar") is revealed until the customer accepts a quotation.
2. **Single-Winner Atomic Lock**:
   - Competing bids are locked to `REJECTED` or `EXPIRED` immediately upon customer acceptance, eliminating merchant double-fulfillment.
3. **Escrow Delivery Verification**:
   - Delivery partner and merchant payouts are held in escrow until the customer's 4-digit OTP is verified at delivery handover.

