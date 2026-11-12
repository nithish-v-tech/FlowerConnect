# 🌸 FlowerConnect - Hyperlocal Flower & Gift Marketplace

> **Hyperlocal flower, bouquet, and gift marketplace platform inspired by Swiggy & Zomato.**  
> Connecting neighborhood flower vendors, small roadside flower stalls, artisan boutique florists, and gift shops with nearby consumers.

---

## 🌟 Key Highlights

- **Swiggy/Zomato Inspired UI/UX**: Geolocation-aware header, dynamic promo banners, circular category navigation, roadside & boutique shop cards, and instant cart stepper.
- **Dynamic Price Quotation System (RFQ)**: Broadcast custom flower requests to nearby florists within a 5 km radius, receive competing quotes, compare prices, and lock in the winning offer.
- **Interactive Custom Bouquet Builder**: 5-step studio allowing customers to choose bases (Korean wrap, glass vase, jute basket, velvet box), flower stems with counts & live costs, luxury ribbons, add-on chocolates/plush toys, and personalized greeting notes.
- **6 Operating Roles Built-in**:
  1. **Customer**: Explore flowers, design bouquets, post RFQs, checkout with UPI/COD, and live track deliveries.
  2. **Flower Merchant**: Manage roadside flower stalls, update daily wholesale mandi prices (Jasmine, Roses, Marigold), and bid on RFQs.
  3. **Bouquet Merchant**: Boutique florist tools, custom arrangements, and packaging options.
  4. **Gift Merchant**: Hampers, chocolates, plush toys, and surprise gift management.
  5. **Delivery Partner**: Online/offline duty toggle, turn-by-turn routing, and OTP proof-of-delivery verification.
  6. **Super Admin**: Commission take-rate slider, merchant KYC verification, GMV analytics, and dispute resolution.
- **Full-Stack Implementation**:
  - **Mobile**: Flutter 3.24+ / Dart 3.5+ with Clean Architecture and Riverpod 3.
  - **Backend**: Python 3.11+ / FastAPI with SQLAlchemy 2.0 async ORM.
  - **Database**: PostgreSQL 16 with Alembic database migrations.
  - **Infrastructure**: Docker & Docker Compose.

---

## 🏗️ Project Architecture

```
e:\FLOWER CONNECT\
├── mobile/                           # Flutter Mobile Application
│   ├── lib/
│   │   ├── core/
│   │   │   ├── theme/                # Swiggy-like design system, colors & typography
│   │   │   ├── models/               # User, Shop, Product, RFQ, Quotation, Order, Custom Bouquet
│   │   │   ├── constants/            # Curated realistic demo data & shop catalog
│   │   │   └── state/                # Riverpod Notifiers (AppState, Cart, RFQ, Order)
│   │   ├── features/
│   │   │   ├── auth/                 # Role switcher sheet & authentication
│   │   │   ├── customer/             # Home screen, shop details, cart checkout, live tracking
│   │   │   ├── bouquet_builder/      # 5-step custom bouquet builder studio
│   │   │   ├── quotation/            # RFQ posting & real-time quotation comparison
│   │   │   ├── merchant/             # Merchant hub, daily price ticker, quote submission
│   │   │   ├── delivery/             # Delivery partner hub, online toggle, OTP verification
│   │   │   ├── admin/                # Platform commissions, KYC, GMV financial ledger
│   │   │   └── shared/               # Reusable cards, status badges, quotation bid cards
│   │   └── main.dart                 # Multi-role root router
│   ├── test/                         # Unit and integration test suite
│   └── pubspec.yaml
│
├── backend/                          # FastAPI Backend
│   ├── app/
│   │   ├── core/                     # Config, security (JWT/hash), database
│   │   ├── models/                   # SQLAlchemy models (User, Shop, Product, RFQ, Quote, Order)
│   │   ├── schemas/                  # Pydantic v2 validation schemas
│   │   ├── services/                 # Fair merchant matching, quotation lock, order engine
│   │   ├── api/v1/                   # REST API routers for all roles
│   │   └── main.py                   # FastAPI application entrypoint
│   ├── alembic/                      # Database migrations
│   ├── tests/                        # Pytest automated test suite
│   ├── Dockerfile                    # Container definition
│   ├── docker-compose.yml            # PostgreSQL 16 + FastAPI
│   └── requirements.txt
│
└── docs/                             # Documentation
    ├── ARCHITECTURE.md               # Architecture specification & sequence diagrams
    ├── API_DOCUMENTATION.md          # REST API documentation & schemas
    └── ANDROID_BUILD_GUIDE.md        # APK / App Bundle generation instructions
```

---

## ⚡ Quick Start Guide

### 1. Run Mobile App (Flutter)
```bash
cd mobile
flutter pub get
flutter run
```
> **Note**: The app operates with responsive reactive state management and realistic data out of the box. Tap the **Role Pill** in the top bar to instantly switch between **Customer**, **Flower Merchant**, **Bouquet Merchant**, **Gift Merchant**, **Delivery Partner**, and **Super Admin**.

### 2. Run Backend (FastAPI + PostgreSQL)
#### Option A: Docker Compose (Recommended)
```bash
cd backend
docker-compose up --build
```
- API Base: `http://localhost:8000`
- Interactive Swagger UI: `http://localhost:8000/docs`

#### Option B: Local Python Execution
```bash
cd backend
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --port 8000
```

---

## 🧪 Running Automated Tests

### Flutter Tests
```bash
cd mobile
flutter test
```
- Tests cart calculation, self-pickup delivery fee waiver, and dynamic quotation bidding with single-winner atomic locking.

### Python Backend Tests
```bash
cd backend
python -m pytest tests -v
```
- Tests Haversine distance calculations, anti-monopoly fair merchant matching algorithm, quotation expiry, and OTP delivery verification.

---

## 📑 Detailed Documentation

- [Architecture & Sequence Diagrams](docs/ARCHITECTURE.md)
- [REST API Specifications](docs/API_DOCUMENTATION.md)
- [Android APK Build Guide](docs/ANDROID_BUILD_GUIDE.md)

