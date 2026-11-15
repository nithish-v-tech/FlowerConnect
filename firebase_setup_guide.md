# FlowerConnect - 100% Free Firebase Spark Plan Setup Guide

This guide details how to configure **Firebase Authentication (Phone)** and **Cloud Firestore** completely free on the **Firebase Spark Plan** without requiring Blaze billing, paid APIs, or a credit card.

---

### Why Firebase Spark Plan is 100% Free

| Service | Spark Plan Allocation (Free) | FlowerConnect Usage |
| :--- | :--- | :--- |
| **Phone Authentication** | Unlimited free test phone numbers | Real Firebase Auth with 0 SMS cost |
| **Cloud Firestore** | 1 GiB storage, 50k reads/day, 20k writes/day | Users, shops, products, orders, RFQs |
| **Firebase Cloud Messaging** | 100% Free and unlimited | Order status & quotation notifications |
| **Hosting & Rules** | Included with zero cost | Role-based Security Rules |

---

### Step 1: Create a Free Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** and name it `flowerconnect-hyperlocal` (or your choice).
3. Disable Google Analytics (optional, keeps setup minimal).
4. Click **Create project**. Ensure the plan displayed is **Spark (Free)**.

---

### Step 2: Configure Test Phone Numbers (Zero SMS Cost)
Firebase Authentication provides a native **"Phone numbers for testing"** feature. When test numbers are used, Firebase verifies them directly inside Firebase Auth **without sending real carrier SMS messages**, using 0 quota and requiring no payment method:

1. In Firebase Console, go to **Build** → **Authentication**.
2. Click **Get started**, then select the **Sign-in method** tab.
3. Click on **Phone** and toggle **Enable**.
4. Scroll down to **"Phone numbers for testing (optional)"**.
5. Add the following test phone numbers and their fixed OTP codes:

| Role in FlowerConnect | Phone Number | Test Verification Code (OTP) | Associated Profile |
| :--- | :--- | :--- | :--- |
| **Customer** | `+91 98765 43210` | `432100` | Pooja Hegde |
| **Approved Flower Stall** | `+91 98450 12345` | `123450` | Muthu Kumar (*Sri Lakshmi Flower Stall*) |
| **Approved Bouquet Studio** | `+91 98451 98765` | `987650` | Ananya Sharma (*Petals & Blooms*) |
| **Approved Gift Boutique** | `+91 99160 55443` | `554430` | Vikram Joshi (*The Velvet Ribbon*) |
| **Pending Vendor (Review)** | `+91 99999 88888` | `888880` | Kavita Reddy (*Sunshine Florist*) |
| **Super Admin** | `+91 90000 00001` | `000010` | Platform Super Admin |
| **Delivery Partner** | `+91 94480 33211` | `332110` | Ramesh Gowda |

6. Click **Save**.

---

### Step 3: Enable Cloud Firestore
1. In Firebase Console, go to **Build** → **Firestore Database**.
2. Click **Create database**.
3. Choose your database location (e.g. `asia-south1` for Mumbai / Bengaluru).
4. Select **Start in test mode** (or production mode).
5. Click **Create**.

#### Deploy Security Rules:
Copy the contents of `firestore.rules` located in the root of this project and paste it into the **Rules** tab of Firestore in the Firebase Console, then click **Publish**.

The rules enforce:
- Regular users cannot register or self-assign the `ADMIN` role.
- Only verified shops (`is_verified == true`) are visible to public customers.
- Only Super Admin can approve pending vendor applications (`is_verified: true`).
- Order records are private to the placing customer, vendor, assigned driver, and admin.

---

### Step 4: Register Android App in Firebase
1. In Firebase Project Overview, click the **Android** icon (`+ Add app`).
2. Enter Android package name: `com.flowerconnect.flower_connect`
3. Enter App nickname: `FlowerConnect`
4. Click **Register app**.
5. Download `google-services.json` and replace `mobile/android/app/google-services.json`.

---

### Step 5: Automatic Database Seeding
When you run FlowerConnect for the first time:
- The app checks if Firestore collections (`shops` and `products`) have data.
- If empty, it automatically populates the initial flower stalls, bouquet arrangements, gifts, and daily flower rates.
- No manual database setup required!

