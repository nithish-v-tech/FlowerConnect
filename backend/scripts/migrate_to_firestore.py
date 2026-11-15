"""
Script to migrate/seed FlowerConnect SQLite data to Cloud Firestore.
Can be executed if you have a Firebase service account JSON key:
    python backend/scripts/migrate_to_firestore.py path/to/serviceAccountKey.json
"""
import sys
import json
import sqlite3
import os

def migrate(service_account_path="serviceAccountKey.json", db_path="backend/flowerconnect.db"):
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError:
        print("Please install firebase-admin: pip install firebase-admin")
        return

    if not os.path.exists(service_account_path):
        print(f"Service account file not found at: {service_account_path}")
        print("Tip: You can download it from Firebase Console -> Project Settings -> Service accounts.")
        return

    if not os.path.exists(db_path):
        print(f"SQLite DB not found at: {db_path}")
        return

    cred = credentials.Certificate(service_account_path)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    # 1. Migrate Users
    cursor.execute("SELECT * FROM users")
    users = cursor.fetchall()
    print(f"Migrating {len(users)} users to Firestore...")
    for u in users:
        u_dict = dict(u)
        u_dict["created_at"] = str(u_dict.get("created_at"))
        db.collection("users").document(u_dict["id"]).set(u_dict, merge=True)

    # 2. Migrate Shops
    cursor.execute("SELECT * FROM shops")
    shops = cursor.fetchall()
    print(f"Migrating {len(shops)} shops to Firestore...")
    for s in shops:
        s_dict = dict(s)
        if s_dict.get("daily_rates") and isinstance(s_dict["daily_rates"], str):
            try:
                s_dict["daily_rates"] = json.loads(s_dict["daily_rates"])
            except:
                pass
        s_dict["created_at"] = str(s_dict.get("created_at"))
        db.collection("shops").document(s_dict["id"]).set(s_dict, merge=True)

    # 3. Migrate Products
    cursor.execute("SELECT * FROM products")
    products = cursor.fetchall()
    print(f"Migrating {len(products)} products to Firestore...")
    for p in products:
        p_dict = dict(p)
        p_dict["created_at"] = str(p_dict.get("created_at"))
        db.collection("products").document(p_dict["id"]).set(p_dict, merge=True)

    # 4. Migrate Orders
    cursor.execute("SELECT * FROM orders")
    orders = cursor.fetchall()
    print(f"Migrating {len(orders)} orders to Firestore...")
    for o in orders:
        o_dict = dict(o)
        if o_dict.get("items_json") and isinstance(o_dict["items_json"], str):
            try:
                o_dict["items"] = json.loads(o_dict["items_json"])
            except:
                pass
        o_dict["created_at"] = str(o_dict.get("created_at"))
        db.collection("orders").document(o_dict["id"]).set(o_dict, merge=True)

    conn.close()
    print("Migration from SQLite to Cloud Firestore completed successfully!")

if __name__ == "__main__":
    sa_path = sys.argv[1] if len(sys.argv) > 1 else "serviceAccountKey.json"
    migrate(sa_path)

