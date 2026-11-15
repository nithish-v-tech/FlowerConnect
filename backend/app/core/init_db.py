import asyncio
import uuid
from datetime import datetime, timedelta
from sqlalchemy import select
from app.core.database import engine, AsyncSessionLocal, Base
from app.models.user import User, UserRole, OTPRecord
from app.models.shop import Shop, ShopType
from app.models.product import Product, ProductCategory
from app.models.order import Order, OrderStatus, OrderFulfillment, PaymentMethod, PaymentStatus
from app.models.rfq import RFQRequest, DeliveryPreference, RFQStatus
from app.models.quotation import Quotation, QuotationStatus

async def init_database():
    """Initializes tables and seeds the database with initial records if empty."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as session:
        # Check if users already exist
        result = await session.execute(select(User).limit(1))
        existing_user = result.scalars().first()

        if not existing_user:
            # 1. Seed Users
            users = [
                User(
                    id="cust_01",
                    email="pooja.h@example.com",
                    phone="+919876543210",
                    full_name="Pooja Hegde",
                    role=UserRole.CUSTOMER,
                    address="14, Greenview Lane, Indiranagar, Bengaluru",
                    is_active=True,
                    is_vendor_approved=True,
                ),
                User(
                    id="merchant_01",
                    email="srilakshmi.flowers@market.in",
                    phone="+919845012345",
                    full_name="Muthu Kumar",
                    role=UserRole.FLOWER_MERCHANT,
                    shop_id="shop_001",
                    address="100ft Road, Near Metro Pillar 84, Indiranagar, Bengaluru",
                    is_active=True,
                    is_vendor_approved=True,
                ),
                User(
                    id="merchant_02",
                    email="petals.studio@bangalore.in",
                    phone="+919845198765",
                    full_name="Ananya Sharma",
                    role=UserRole.BOUQUET_MERCHANT,
                    shop_id="shop_002",
                    address="5th Block, 80ft Road, Koramangala, Bengaluru",
                    is_active=True,
                    is_vendor_approved=True,
                ),
                User(
                    id="merchant_03",
                    email="velvet.ribbon@gifts.in",
                    phone="+919916055443",
                    full_name="Vikram Joshi",
                    role=UserRole.GIFT_MERCHANT,
                    shop_id="shop_003",
                    address="27th Main, Sector 1, HSR Layout, Bengaluru",
                    is_active=True,
                    is_vendor_approved=True,
                ),
                User(
                    id="merchant_pending_01",
                    email="kavita.sunshine@gmail.com",
                    phone="+919999988888",
                    full_name="Kavita Reddy",
                    role=UserRole.FLOWER_MERCHANT,
                    shop_id="shop_pending_01",
                    address="12th Main, HAL 2nd Stage, Indiranagar, Bengaluru",
                    is_active=True,
                    is_vendor_approved=False,  # PENDING ADMIN APPROVAL
                ),
                User(
                    id="admin_01",
                    email="admin@flowerconnect.app",
                    phone="+919000000001",
                    full_name="Antigravity Super Admin",
                    role=UserRole.ADMIN,
                    address="FlowerConnect HQ, Bengaluru",
                    is_active=True,
                    is_vendor_approved=True,
                ),
                User(
                    id="driver_01",
                    email="ramesh.delivery@connect.in",
                    phone="+919448033211",
                    full_name="Ramesh Gowda",
                    role=UserRole.DELIVERY_PARTNER,
                    address="Indiranagar Hub, Bengaluru",
                    is_active=True,
                    is_vendor_approved=True,
                ),
            ]
            for u in users:
                session.add(u)

            # 2. Seed Shops
            shops = [
                Shop(
                    id="shop_001",
                    user_id="merchant_01",
                    name="Sri Lakshmi Flower Stall",
                    shop_type=ShopType.FLOWER_SHOP,
                    address="100ft Road, Near Metro Pillar 84, Indiranagar, Bengaluru",
                    latitude=12.9716,
                    longitude=77.6412,
                    rating=4.8,
                    total_reviews=248,
                    image_url="https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=600&q=80",
                    is_verified=True,
                    is_featured=True,
                    is_open=True,
                    owner_name="Muthu Kumar",
                    contact_phone="+919845012345",
                    daily_rates={
                        "Fresh Jasmine (Madurai Malli)": 480.0,
                        "Dutch Red Roses (20 stems)": 280.0,
                        "Yellow Marigold (Genda kg)": 120.0,
                        "Lotus (Pooja Pair)": 80.0,
                        "Chrysanthemum (Sevvanthi kg)": 160.0,
                    },
                ),
                Shop(
                    id="shop_002",
                    user_id="merchant_02",
                    name="Petals & Blooms Studio",
                    shop_type=ShopType.BOUQUET_SHOP,
                    address="5th Block, 80ft Road, Koramangala, Bengaluru",
                    latitude=12.9352,
                    longitude=77.6245,
                    rating=4.9,
                    total_reviews=512,
                    image_url="https://images.unsplash.com/photo-1526047932273-341f2a7631f9?auto=format&fit=crop&w=600&q=80",
                    is_verified=True,
                    is_featured=True,
                    is_open=True,
                    owner_name="Ananya Sharma",
                    contact_phone="+919845198765",
                    daily_rates={
                        "Stem Red Rose (Single)": 35.0,
                        "Stem White Asiatic Lily": 75.0,
                        "Blue Dendrobium Orchid": 95.0,
                        "Carnations (Bunch of 10)": 350.0,
                        "Baby Breath (Filler bunch)": 180.0,
                    },
                ),
                Shop(
                    id="shop_003",
                    user_id="merchant_03",
                    name="The Velvet Ribbon Gifts & Florals",
                    shop_type=ShopType.GIFT_SHOP,
                    address="27th Main, Sector 1, HSR Layout, Bengaluru",
                    latitude=12.9116,
                    longitude=77.6473,
                    rating=4.7,
                    total_reviews=189,
                    image_url="https://images.unsplash.com/photo-1513519245088-0e12902e5a38?auto=format&fit=crop&w=600&q=80",
                    is_verified=True,
                    is_featured=False,
                    is_open=True,
                    owner_name="Vikram Joshi",
                    contact_phone="+919916055443",
                    daily_rates={
                        "Luxury Ferrero Hamper": 850.0,
                        "Handmade Greeting Cards": 120.0,
                        "Mini Teddy & Rose Combo": 499.0,
                    },
                ),
                Shop(
                    id="shop_pending_01",
                    user_id="merchant_pending_01",
                    name="Sunshine Florist & Gifts",
                    shop_type=ShopType.FLOWER_SHOP,
                    address="12th Main, HAL 2nd Stage, Indiranagar, Bengaluru",
                    latitude=12.9680,
                    longitude=77.6490,
                    rating=0.0,
                    total_reviews=0,
                    image_url="https://images.unsplash.com/photo-1526047932273-341f2a7631f9?auto=format&fit=crop&w=600&q=80",
                    is_verified=False,  # PENDING ADMIN VERIFICATION
                    is_featured=False,
                    is_open=False,
                    owner_name="Kavita Reddy",
                    contact_phone="+919999988888",
                    daily_rates={
                        "Fresh Marigold (kg)": 100.0,
                        "Red Roses (Stems)": 250.0,
                    },
                ),
            ]
            for s in shops:
                session.add(s)

            # 3. Seed Products
            products = [
                Product(
                    id="prod_001",
                    shop_id="shop_002",
                    name="Midnight Crimson - 24 Red Roses",
                    description="Hand-tied arrangement of 24 premium Grade-A Dutch red roses with eucalyptus and gypsophila wrapping in Korean waterproof matte paper.",
                    category=ProductCategory.ROSES,
                    price=899.0,
                    original_price=1199.0,
                    unit="Bouquet",
                    image_url="https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=600&q=80",
                    rating=4.9,
                    reviews_count=142,
                    in_stock=True,
                    is_bestseller=True,
                ),
                Product(
                    id="prod_002",
                    shop_id="shop_001",
                    name="Madurai Fragrant Jasmine (Malli)",
                    description="Hand-picked morning harvest fresh Jasmine string. Pristine white blossoms tied with traditional banana fiber. Ideal for daily pooja & hair adornment.",
                    category=ProductCategory.FRESH_FLOWERS,
                    price=240.0,
                    original_price=280.0,
                    unit="250 grams",
                    image_url="https://images.unsplash.com/photo-1606041008023-472dfb5e530f?auto=format&fit=crop&w=600&q=80",
                    rating=4.8,
                    reviews_count=210,
                    in_stock=True,
                    is_bestseller=True,
                ),
                Product(
                    id="prod_003",
                    shop_id="shop_003",
                    name="Ferrero & Rose Elegance Hamper",
                    description="Box of 16 Ferrero Rocher chocolates paired with 10 long-stem preserved red roses and personalized greeting note in a velvet keepsake box.",
                    category=ProductCategory.GIFT_HAMPERS,
                    price=1499.0,
                    original_price=1799.0,
                    unit="Gift Box",
                    image_url="https://images.unsplash.com/photo-1549465220-1a8b9238cd48?auto=format&fit=crop&w=600&q=80",
                    rating=4.9,
                    reviews_count=76,
                    in_stock=True,
                    is_bestseller=True,
                ),
                Product(
                    id="prod_004",
                    shop_id="shop_001",
                    name="Traditional Marigold Garland (Genda Mala)",
                    description="Freshly woven 4-feet dense orange and yellow marigold garland for doorway, temple deity, or car decor.",
                    category=ProductCategory.FRESH_FLOWERS,
                    price=180.0,
                    original_price=220.0,
                    unit="Single Garland (4 ft)",
                    image_url="https://images.unsplash.com/photo-1596704017254-9b121068fb31?auto=format&fit=crop&w=600&q=80",
                    rating=4.7,
                    reviews_count=88,
                    in_stock=True,
                    is_bestseller=False,
                ),
                Product(
                    id="prod_005",
                    shop_id="shop_002",
                    name="Pastel Pink Asiatic Lily & Gypsophila",
                    description="Exquisite bunch of 6 blooming pink Asiatic lilies paired with baby's breath fillers wrapped in blush satin ribbon.",
                    category=ProductCategory.LILIES,
                    price=749.0,
                    original_price=899.0,
                    unit="Vase Arrangement",
                    image_url="https://images.unsplash.com/photo-1508610048659-a06b669e3321?auto=format&fit=crop&w=600&q=80",
                    rating=4.8,
                    reviews_count=64,
                    in_stock=True,
                    is_bestseller=False,
                ),
                Product(
                    id="prod_006",
                    shop_id="shop_002",
                    name="Royal Blue Dendrobium Orchids",
                    description="Striking exotic bunch of 8 stems of deep electric blue dyed orchids wrapped with black luxury craft paper.",
                    category=ProductCategory.EXOTICS,
                    price=849.0,
                    original_price=999.0,
                    unit="Bunch of 8 stems",
                    image_url="https://images.unsplash.com/photo-1567696911980-2eed69a46042?auto=format&fit=crop&w=600&q=80",
                    rating=4.9,
                    reviews_count=93,
                    in_stock=True,
                    is_bestseller=True,
                ),
                Product(
                    id="prod_007",
                    shop_id="shop_003",
                    name="Swiss Truffles & Mini Teddy Combo",
                    description="Artisanal cocoa-dusted Swiss dark chocolate truffles accompanied by an adorable 6-inch plush teddy bear and romantic card.",
                    category=ProductCategory.CHOCOLATES,
                    price=699.0,
                    original_price=799.0,
                    unit="Gift Combo",
                    image_url="https://images.unsplash.com/photo-1549007994-cb92caebd54b?auto=format&fit=crop&w=600&q=80",
                    rating=4.6,
                    reviews_count=41,
                    in_stock=True,
                    is_bestseller=False,
                ),
                Product(
                    id="prod_008",
                    shop_id="shop_001",
                    name="Lotus Pooja Pair (Kamal Pushpa)",
                    description="Pair of fresh sacred pink lotus buds with long stems, harvested early morning for Lakshmi pooja.",
                    category=ProductCategory.FRESH_FLOWERS,
                    price=110.0,
                    original_price=130.0,
                    unit="Pair (2 flowers)",
                    image_url="https://images.unsplash.com/photo-1509198397868-475647b2a1e5?auto=format&fit=crop&w=600&q=80",
                    rating=4.9,
                    reviews_count=175,
                    in_stock=True,
                    is_bestseller=True,
                ),
            ]
            for p in products:
                session.add(p)

            # 4. Seed Initial Orders
            orders = [
                Order(
                    id="ORD-98421",
                    customer_id="cust_01",
                    customer_name="Pooja Hegde",
                    customer_phone="+919876543210",
                    shop_id="shop_002",
                    shop_name="Petals & Blooms Studio",
                    quotation_id=None,
                    items_json=[
                        {
                            "id": "prod_001",
                            "name": "Midnight Crimson - 24 Red Roses",
                            "quantity": 1,
                            "price": 899.0,
                            "unit": "Bouquet",
                        },
                        {
                            "id": "prod_007",
                            "name": "Swiss Truffles & Mini Teddy Combo",
                            "quantity": 1,
                            "price": 699.0,
                            "unit": "Gift Combo",
                        },
                    ],
                    items_total=1598.0,
                    delivery_fee=40.0,
                    platform_commission=159.8,
                    grand_total=1638.0,
                    fulfillment=OrderFulfillment.HOME_DELIVERY,
                    payment_method=PaymentMethod.UPI,
                    payment_status=PaymentStatus.PAID,
                    status=OrderStatus.OUT_FOR_DELIVERY,
                    delivery_address="Flat 402, Oakwood Heights, 12th Main Indiranagar, Bengaluru",
                    delivery_otp="4821",
                    driver_id="driver_01",
                    driver_name="Ramesh Gowda",
                    driver_phone="+919448033211",
                    is_surprise_delivery=True,
                    surprise_recipient_name="Rahul Hegde",
                    surprise_note="Happy Anniversary my love! Here is to forever.",
                    created_at=datetime.utcnow(),
                ),
                Order(
                    id="ORD-98310",
                    customer_id="cust_01",
                    customer_name="Pooja Hegde",
                    customer_phone="+919876543210",
                    shop_id="shop_001",
                    shop_name="Sri Lakshmi Flower Stall",
                    quotation_id=None,
                    items_json=[
                        {
                            "id": "prod_002",
                            "name": "Madurai Fragrant Jasmine (Malli)",
                            "quantity": 2,
                            "price": 240.0,
                            "unit": "250 grams",
                        },
                        {
                            "id": "prod_008",
                            "name": "Lotus Pooja Pair (Kamal Pushpa)",
                            "quantity": 1,
                            "price": 110.0,
                            "unit": "Pair (2 flowers)",
                        },
                    ],
                    items_total=590.0,
                    delivery_fee=0.0,
                    platform_commission=59.0,
                    grand_total=590.0,
                    fulfillment=OrderFulfillment.SELF_PICKUP,
                    payment_method=PaymentMethod.UPI,
                    payment_status=PaymentStatus.PAID,
                    status=OrderStatus.DELIVERED,
                    delivery_address="Self-Pickup at 100ft Road, Indiranagar",
                    delivery_otp="1192",
                    driver_id=None,
                    driver_name=None,
                    created_at=datetime.utcnow() - timedelta(days=1),
                ),
            ]
            for o in orders:
                session.add(o)

            await session.commit()
            print("[Database] Schema created & seeded with initial FlowerConnect data successfully!")

