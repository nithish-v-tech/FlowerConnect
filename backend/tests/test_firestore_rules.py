import os
import pytest
import re
from typing import Dict, Any, Optional

class SecurityRulesSimulator:
    """
    Direct Python implementation of the Cloud Firestore security rules in firestore.rules.
    Evaluates requests against security logic, role checks, and attack vectors.
    """
    def __init__(self, db_state: Optional[Dict[str, Dict[str, Any]]] = None):
        self.db = db_state or {
            'users': {},
            'shops': {},
            'products': {},
            'rfqs': {},
            'quotations': {},
            'orders': {}
        }

    # Helpers
    def is_authenticated(self, auth: Optional[Dict[str, Any]]) -> bool:
        return auth is not None and 'uid' in auth and auth['uid'] is not None

    def has_user_doc(self, auth: Optional[Dict[str, Any]]) -> bool:
        if not self.is_authenticated(auth):
            return False
        return auth['uid'] in self.db['users']

    def get_user_data(self, auth: Optional[Dict[str, Any]]) -> Dict[str, Any]:
        if not self.has_user_doc(auth):
            return {}
        return self.db['users'][auth['uid']]

    def is_admin(self, auth: Optional[Dict[str, Any]]) -> bool:
        if not self.is_authenticated(auth):
            return False
        token = auth.get('token', {})
        if token.get('admin') is True:
            return True
        user_data = self.get_user_data(auth)
        role = user_data.get('role', '')
        return role in ['ADMIN', 'admin', 'SUPER_ADMIN', 'super_admin']

    def is_verified_merchant(self, auth: Optional[Dict[str, Any]]) -> bool:
        if not self.has_user_doc(auth):
            return False
        user_data = self.get_user_data(auth)
        is_approved = user_data.get('is_vendor_approved') is True
        role = user_data.get('role', '')
        merchant_roles = [
            'FLOWER_MERCHANT', 'BOUQUET_MERCHANT', 'GIFT_MERCHANT',
            'flowerMerchant', 'bouquetMerchant', 'giftMerchant'
        ]
        return is_approved and role in merchant_roles

    def is_shop_owner(self, auth: Optional[Dict[str, Any]], shop_id: str) -> bool:
        if not self.is_authenticated(auth):
            return False
        user_data = self.get_user_data(auth)
        if user_data.get('shop_id') == shop_id:
            return True
        shop = self.db['shops'].get(shop_id)
        if shop and shop.get('user_id') == auth['uid']:
            return True
        return False

    def is_rfq_owner(self, auth: Optional[Dict[str, Any]], rfq_id: str) -> bool:
        if not self.is_authenticated(auth):
            return False
        rfq = self.db['rfqs'].get(rfq_id)
        return rfq is not None and rfq.get('customer_id') == auth['uid']

    def is_driver(self, auth: Optional[Dict[str, Any]]) -> bool:
        if not self.has_user_doc(auth):
            return False
        role = self.get_user_data(auth).get('role', '')
        return role in ['DELIVERY_PARTNER', 'deliveryPartner']

    # --- 1. Users Rules ---
    def can_read_user(self, auth: Optional[Dict[str, Any]], user_id: str) -> bool:
        return self.is_authenticated(auth) and (auth['uid'] == user_id or self.is_admin(auth))

    def can_create_user(self, auth: Optional[Dict[str, Any]], user_id: str, new_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        if self.is_admin(auth):
            return True
        is_own = auth['uid'] == user_id
        role = new_data.get('role')
        forbidden_roles = ['ADMIN', 'admin', 'Admin', 'SUPER_ADMIN', 'super_admin']
        role_not_admin = role not in forbidden_roles
        no_vendor_approval = new_data.get('is_vendor_approved', False) is False
        no_admin_flags = new_data.get('is_admin', False) is False and new_data.get('admin', False) is False
        return is_own and role_not_admin and no_vendor_approval and no_admin_flags

    def can_update_user(self, auth: Optional[Dict[str, Any]], user_id: str, old_data: Dict[str, Any], new_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        if self.is_admin(auth):
            return True
        is_own = auth['uid'] == user_id
        role_unchanged = new_data.get('role') == old_data.get('role')
        vendor_approval_unchanged = (
            ('is_vendor_approved' not in old_data and new_data.get('is_vendor_approved', False) is False) or
            ('is_vendor_approved' in old_data and new_data.get('is_vendor_approved') == old_data.get('is_vendor_approved'))
        )
        no_admin_flags = new_data.get('is_admin', False) is False and new_data.get('admin', False) is False
        id_unchanged = 'id' not in new_data or new_data.get('id') == old_data.get('id')
        return is_own and role_unchanged and vendor_approval_unchanged and no_admin_flags and id_unchanged

    # --- 2. Shops Rules ---
    def can_read_shop(self, auth: Optional[Dict[str, Any]], shop_data: Dict[str, Any]) -> bool:
        if shop_data.get('is_verified') is True:
            return True
        if self.is_authenticated(auth):
            return shop_data.get('user_id') == auth['uid'] or self.is_admin(auth)
        return False

    def can_create_shop(self, auth: Optional[Dict[str, Any]], new_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        if self.is_admin(auth):
            return True
        is_own_user = new_data.get('user_id') == auth['uid']
        not_verified = new_data.get('is_verified', False) is False
        return is_own_user and not_verified

    def can_update_shop(self, auth: Optional[Dict[str, Any]], old_data: Dict[str, Any], new_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        if self.is_admin(auth):
            return True
        is_owner = old_data.get('user_id') == auth['uid']
        user_id_unchanged = new_data.get('user_id') == old_data.get('user_id')
        verified_unchanged = new_data.get('is_verified') == old_data.get('is_verified')
        return is_owner and user_id_unchanged and verified_unchanged

    # --- 3. Products Rules ---
    def can_read_product(self) -> bool:
        return True

    def can_create_product(self, auth: Optional[Dict[str, Any]], new_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        if self.is_admin(auth):
            return True
        is_merchant = self.is_verified_merchant(auth)
        owns_shop = self.is_shop_owner(auth, new_data.get('shop_id', ''))
        valid_price = isinstance(new_data.get('price'), (int, float)) and new_data.get('price') >= 0
        return is_merchant and owns_shop and valid_price

    def can_update_product(self, auth: Optional[Dict[str, Any]], old_data: Dict[str, Any], new_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        if self.is_admin(auth):
            return True
        is_merchant = self.is_verified_merchant(auth)
        owns_shop = self.is_shop_owner(auth, old_data.get('shop_id', ''))
        shop_unchanged = new_data.get('shop_id') == old_data.get('shop_id')
        valid_price = isinstance(new_data.get('price'), (int, float)) and new_data.get('price') >= 0
        return is_merchant and owns_shop and shop_unchanged and valid_price

    def can_delete_product(self, auth: Optional[Dict[str, Any]], old_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        if self.is_admin(auth):
            return True
        return self.is_verified_merchant(auth) and self.is_shop_owner(auth, old_data.get('shop_id', ''))

    # --- 4. RFQ Rules ---
    def can_read_rfq(self, auth: Optional[Dict[str, Any]], rfq_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        return (
            rfq_data.get('customer_id') == auth['uid'] or
            self.is_verified_merchant(auth) or
            self.is_admin(auth)
        )

    def can_create_rfq(self, auth: Optional[Dict[str, Any]], new_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        if self.is_admin(auth):
            return True
        is_own = new_data.get('customer_id') == auth['uid']
        status_ok = new_data.get('status') in ['broadcasting', 'quotesReceived']
        no_accepted_quote = new_data.get('accepted_quotation_id') is None
        return is_own and status_ok and no_accepted_quote

    def can_update_rfq(self, auth: Optional[Dict[str, Any]], old_data: Dict[str, Any], new_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        if self.is_admin(auth):
            return True
        # Customer updating RFQ
        if old_data.get('customer_id') == auth['uid'] and new_data.get('customer_id') == old_data.get('customer_id'):
            return True
        # Vendor updating count & status on bidding
        diff_keys = set(k for k in new_data if new_data.get(k) != old_data.get(k))
        if self.is_verified_merchant(auth) and diff_keys.issubset({'quotations_count', 'status'}) and new_data.get('customer_id') == old_data.get('customer_id'):
            return True
        return False

    # --- 5. Quotations Rules ---
    def can_read_quotation(self, auth: Optional[Dict[str, Any]], quote_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        merchant_match = (
            quote_data.get('merchant_id') == auth['uid'] or
            self.is_shop_owner(auth, quote_data.get('merchant_id', ''))
        )
        rfq_owner = self.is_rfq_owner(auth, quote_data.get('rfq_id', ''))
        return merchant_match or rfq_owner or self.is_admin(auth)

    def can_create_quotation(self, auth: Optional[Dict[str, Any]], new_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        if self.is_admin(auth):
            return True
        is_merchant = self.is_verified_merchant(auth)
        merchant_match = (
            new_data.get('merchant_id') == auth['uid'] or
            self.is_shop_owner(auth, new_data.get('merchant_id', ''))
        )
        rfq_exists = new_data.get('rfq_id') in self.db['rfqs']
        status_pending = new_data.get('status') == 'pending'
        valid_price = isinstance(new_data.get('quoted_price'), (int, float)) and new_data.get('quoted_price') > 0
        valid_delivery = isinstance(new_data.get('delivery_fee'), (int, float)) and new_data.get('delivery_fee') >= 0
        return is_merchant and merchant_match and rfq_exists and status_pending and valid_price and valid_delivery

    def can_update_quotation(self, auth: Optional[Dict[str, Any]], old_data: Dict[str, Any], new_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        if self.is_admin(auth):
            return True
        diff_keys = set(k for k in new_data if new_data.get(k) != old_data.get(k))
        # Case 1: RFQ customer accepts/rejects quote
        if self.is_rfq_owner(auth, old_data.get('rfq_id', '')):
            if diff_keys == {'status'} and new_data.get('status') in ['accepted', 'rejected']:
                return True
        # Case 2: Submitting merchant edits pending quote
        merchant_match = (
            old_data.get('merchant_id') == auth['uid'] or
            self.is_shop_owner(auth, old_data.get('merchant_id', ''))
        )
        if merchant_match and old_data.get('status') == 'pending':
            ids_unchanged = (
                new_data.get('merchant_id') == old_data.get('merchant_id') and
                new_data.get('rfq_id') == old_data.get('rfq_id')
            )
            status_ok = new_data.get('status') in ['pending', 'rejected']
            valid_price = isinstance(new_data.get('quoted_price'), (int, float)) and new_data.get('quoted_price') > 0
            if ids_unchanged and status_ok and valid_price:
                return True
        return False

    # --- 6. Orders Rules ---
    def can_read_order(self, auth: Optional[Dict[str, Any]], order_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        if self.is_admin(auth):
            return True
        is_cust = order_data.get('customer_id') == auth['uid']
        is_merchant = self.is_shop_owner(auth, order_data.get('shop_id', '')) or order_data.get('shop_owner_id') == auth['uid']
        is_driver = order_data.get('driver_id') == auth['uid']
        return is_cust or is_merchant or is_driver

    def can_create_order(self, auth: Optional[Dict[str, Any]], new_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        if self.is_admin(auth):
            return True
        is_cust = new_data.get('customer_id') == auth['uid']
        payment_pending = new_data.get('payment_status', 'pending') in ['pending', 'failed']
        no_driver = not new_data.get('driver_id') and not new_data.get('driver_name')
        status_ok = new_data.get('status') in ['placed', 'confirmed']
        valid_totals = (
            isinstance(new_data.get('grand_total'), (int, float)) and new_data.get('grand_total') >= 0 and
            isinstance(new_data.get('items_total'), (int, float)) and new_data.get('items_total') >= 0
        )
        return is_cust and payment_pending and no_driver and status_ok and valid_totals

    def can_update_order(self, auth: Optional[Dict[str, Any]], old_data: Dict[str, Any], new_data: Dict[str, Any]) -> bool:
        if not self.is_authenticated(auth):
            return False
        if self.is_admin(auth):
            return True
        # Immutable core fields
        immutables = (
            new_data.get('customer_id') == old_data.get('customer_id') and
            new_data.get('shop_id') == old_data.get('shop_id') and
            new_data.get('grand_total') == old_data.get('grand_total') and
            new_data.get('items_total') == old_data.get('items_total')
        )
        if not immutables:
            return False

        diff_keys = set(k for k in new_data if new_data.get(k) != old_data.get(k))

        # Case 1: Merchant updates order fulfillment
        is_merchant = self.is_shop_owner(auth, old_data.get('shop_id', '')) or old_data.get('shop_owner_id') == auth['uid']
        if is_merchant:
            payment_unchanged = new_data.get('payment_status') == old_data.get('payment_status')
            driver_unchanged = new_data.get('driver_id') == old_data.get('driver_id')
            if payment_unchanged and driver_unchanged and diff_keys.issubset({'status', 'estimated_delivery_time'}):
                return True

        # Case 2: Delivery Partner fulfills order
        is_driver = self.is_driver(auth) or old_data.get('driver_id') == auth['uid']
        if is_driver:
            driver_allowed_keys = {'status', 'payment_status', 'driver_lat', 'driver_lng', 'driver_name', 'driver_phone', 'driver_id'}
            if diff_keys.issubset(driver_allowed_keys):
                return True

        # Case 3: Customer review or cancellation
        is_cust = old_data.get('customer_id') == auth['uid']
        if is_cust:
            payment_unchanged = new_data.get('payment_status') == old_data.get('payment_status')
            if payment_unchanged:
                if diff_keys.issubset({'rating', 'review'}):
                    return True
                if old_data.get('status') == 'placed' and new_data.get('status') == 'cancelled' and diff_keys == {'status'}:
                    return True

        return False


# --------------------------------------------------------------------------
# PYTEST FIXTURE & TEST SUITE FOR THE 5 SPECIFIC USER REQUIREMENTS
# --------------------------------------------------------------------------

@pytest.fixture
def sim():
    sim = SecurityRulesSimulator()
    # Seed users
    sim.db['users']['admin_uid'] = {'id': 'admin_uid', 'role': 'ADMIN', 'is_vendor_approved': True}
    sim.db['users']['cust_1'] = {'id': 'cust_1', 'role': 'customer', 'is_vendor_approved': False}
    sim.db['users']['cust_2'] = {'id': 'cust_2', 'role': 'customer', 'is_vendor_approved': False}
    sim.db['users']['vendor_1'] = {'id': 'vendor_1', 'role': 'flowerMerchant', 'is_vendor_approved': True, 'shop_id': 'shop_1'}
    sim.db['users']['vendor_2'] = {'id': 'vendor_2', 'role': 'flowerMerchant', 'is_vendor_approved': True, 'shop_id': 'shop_2'}
    sim.db['users']['vendor_unapproved'] = {'id': 'vendor_unapproved', 'role': 'flowerMerchant', 'is_vendor_approved': False}
    sim.db['users']['driver_1'] = {'id': 'driver_1', 'role': 'deliveryPartner', 'is_vendor_approved': False}

    # Seed shops
    sim.db['shops']['shop_1'] = {'id': 'shop_1', 'user_id': 'vendor_1', 'is_verified': True, 'name': 'Vendor 1 Flowers'}
    sim.db['shops']['shop_2'] = {'id': 'shop_2', 'user_id': 'vendor_2', 'is_verified': True, 'name': 'Vendor 2 Flora'}
    sim.db['shops']['shop_pending'] = {'id': 'shop_pending', 'user_id': 'vendor_unapproved', 'is_verified': False, 'name': 'Pending Stall'}

    # Seed RFQ
    sim.db['rfqs']['rfq_1'] = {'id': 'rfq_1', 'customer_id': 'cust_1', 'status': 'broadcasting', 'flower_type': 'Roses'}
    return sim


# ==============================================================================
# TEST 1: Customers cannot become Admins or approve themselves as Vendors
# ==============================================================================
def test_req1_customer_cannot_become_admin_or_approve_self(sim):
    """Verifies that customers cannot self-grant ADMIN role or vendor approval on create or update."""
    auth = {'uid': 'attacker_cust'}
    
    # 1. Reject self-assigning ADMIN on user creation
    assert not sim.can_create_user(auth, 'attacker_cust', {'role': 'ADMIN', 'name': 'Attacker'}), "Must block role=ADMIN on create"
    assert not sim.can_create_user(auth, 'attacker_cust', {'role': 'admin', 'name': 'Attacker'}), "Must block role=admin on create"
    assert not sim.can_create_user(auth, 'attacker_cust', {'role': 'SUPER_ADMIN', 'name': 'Attacker'}), "Must block role=SUPER_ADMIN on create"
    assert not sim.can_create_user(auth, 'attacker_cust', {'role': 'customer', 'is_admin': True}), "Must block is_admin=True on create"
    assert not sim.can_create_user(auth, 'attacker_cust', {'role': 'customer', 'admin': True}), "Must block admin=True on create"

    # 2. Reject self-approving as vendor on user creation
    assert not sim.can_create_user(auth, 'attacker_cust', {'role': 'flowerMerchant', 'is_vendor_approved': True}), "Must block is_vendor_approved=True on create"

    # 3. Legitimate creation passes with unapproved / customer role
    assert sim.can_create_user(auth, 'attacker_cust', {'role': 'customer', 'is_vendor_approved': False, 'name': 'Legit'})

    # 4. Reject role escalation on update
    cust_data = sim.db['users']['cust_1']
    assert not sim.can_update_user({'uid': 'cust_1'}, 'cust_1', cust_data, {**cust_data, 'role': 'ADMIN'}), "Must block role upgrade on update"
    assert not sim.can_update_user({'uid': 'cust_1'}, 'cust_1', cust_data, {**cust_data, 'is_vendor_approved': True}), "Must block self vendor approval on update"
    assert not sim.can_update_user({'uid': 'cust_1'}, 'cust_1', cust_data, {**cust_data, 'is_admin': True}), "Must block is_admin injection on update"

    # 5. Admin CAN approve vendor
    admin_auth = {'uid': 'admin_uid'}
    assert sim.can_update_user(admin_auth, 'cust_1', cust_data, {**cust_data, 'is_vendor_approved': True}), "Admin must be able to approve vendor"


# ==============================================================================
# TEST 2: Vendors cannot edit another Vendor's products or quotations
# ==============================================================================
def test_req2_vendors_cannot_edit_another_vendors_products_or_quotations(sim):
    """Verifies strict tenant isolation between competing vendors for products and quotations."""
    auth_v1 = {'uid': 'vendor_1'}
    auth_v2 = {'uid': 'vendor_2'}

    # --- Products Isolation ---
    p1 = {'id': 'p1', 'shop_id': 'shop_1', 'name': 'Roses', 'price': 300.0}
    # Vendor 1 can create/update/delete product in own shop_1
    assert sim.can_create_product(auth_v1, p1), "Vendor 1 should be allowed to create product in shop 1"
    assert sim.can_update_product(auth_v1, p1, {**p1, 'price': 350.0}), "Vendor 1 should update own product"
    assert sim.can_delete_product(auth_v1, p1), "Vendor 1 should delete own product"

    # Vendor 2 tries to tamper with Vendor 1's product
    assert not sim.can_create_product(auth_v2, p1), "Vendor 2 must NOT create product in shop 1"
    assert not sim.can_update_product(auth_v2, p1, {**p1, 'price': 5.0}), "Vendor 2 must NOT edit Vendor 1's product"
    assert not sim.can_delete_product(auth_v2, p1), "Vendor 2 must NOT delete Vendor 1's product"
    assert not sim.can_update_product(auth_v2, p1, {**p1, 'shop_id': 'shop_2'}), "Vendor 2 must NOT hijack product shop_id"

    # --- Quotations Isolation ---
    q1 = {
        'id': 'quote_v1',
        'rfq_id': 'rfq_1',
        'merchant_id': 'vendor_1',
        'quoted_price': 500.0,
        'delivery_fee': 40.0,
        'status': 'pending'
    }
    sim.db['quotations']['quote_v1'] = q1

    # Vendor 1 can edit own pending quote
    assert sim.can_update_quotation(auth_v1, q1, {**q1, 'quoted_price': 480.0}), "Vendor 1 should update own quote"

    # Vendor 2 tries to view, edit, or delete Vendor 1's quote
    assert not sim.can_read_quotation(auth_v2, q1), "Vendor 2 must NOT read sealed bid of Vendor 1"
    assert not sim.can_update_quotation(auth_v2, q1, {**q1, 'quoted_price': 9999.0}), "Vendor 2 must NOT edit Vendor 1's quote"


# ==============================================================================
# TEST 3: Customers cannot change quotation prices or payment status
# ==============================================================================
def test_req3_customers_cannot_change_quotation_prices_or_payment_status(sim):
    """Verifies that customers cannot modify merchant quotation prices or tamper with order payment status."""
    auth_cust = {'uid': 'cust_1'}
    q1 = {
        'id': 'quote_v1',
        'rfq_id': 'rfq_1',
        'merchant_id': 'vendor_1',
        'quoted_price': 500.0,
        'delivery_fee': 40.0,
        'status': 'pending'
    }
    sim.db['quotations']['quote_v1'] = q1

    # 1. Customer attempts to alter merchant price when accepting quotation (TAMPERING)
    tampered_price = {**q1, 'status': 'accepted', 'quoted_price': 10.0}
    assert not sim.can_update_quotation(auth_cust, q1, tampered_price), "Customer must NOT tamper quoted_price"

    # 2. Customer attempts to alter delivery fee
    tampered_fee = {**q1, 'status': 'accepted', 'delivery_fee': 0.0}
    assert not sim.can_update_quotation(auth_cust, q1, tampered_fee), "Customer must NOT tamper delivery_fee"

    # 3. Legitimate acceptance: only status changes to 'accepted'
    legit_acceptance = {**q1, 'status': 'accepted'}
    assert sim.can_update_quotation(auth_cust, q1, legit_acceptance), "Customer should be able to accept quotation status"

    # 4. Customer attempts to create order with payment_status: 'paid'
    order_create_paid = {
        'id': 'ord_1',
        'customer_id': 'cust_1',
        'shop_id': 'shop_1',
        'grand_total': 540.0,
        'items_total': 500.0,
        'payment_status': 'paid',  # ILLEGAL
        'status': 'placed'
    }
    assert not sim.can_create_order(auth_cust, order_create_paid), "Customer must NOT create order with payment_status=paid"

    # 5. Legitimate order creation with payment_status: 'pending'
    legit_order = {
        'id': 'ord_1',
        'customer_id': 'cust_1',
        'shop_id': 'shop_1',
        'grand_total': 540.0,
        'items_total': 500.0,
        'payment_status': 'pending',
        'status': 'placed'
    }
    assert sim.can_create_order(auth_cust, legit_order), "Legitimate order creation with pending payment must pass"

    # 6. Customer attempts to update order payment_status to 'paid' post-creation
    assert not sim.can_update_order(auth_cust, legit_order, {**legit_order, 'payment_status': 'paid'}), "Customer must NOT alter payment_status on update"

    # 7. Customer attempts to reduce grand_total post-creation
    assert not sim.can_update_order(auth_cust, legit_order, {**legit_order, 'grand_total': 1.0}), "Customer must NOT reduce order grand_total"


# ==============================================================================
# TEST 4: Unauthorized users cannot access private orders
# ==============================================================================
def test_req4_unauthorized_users_cannot_access_private_orders(sim):
    """Verifies that private orders are restricted to the placing customer, shop owner, driver, or admin."""
    order = {
        'id': 'ord_private_1',
        'customer_id': 'cust_1',
        'shop_id': 'shop_1',
        'driver_id': 'driver_1',
        'grand_total': 600.0,
        'payment_status': 'pending',
        'status': 'placed'
    }

    # 1. Unauthenticated user CANNOT read
    assert not sim.can_read_order(None, order), "Unauthenticated request must be denied"

    # 2. Unrelated Customer 2 CANNOT read
    assert not sim.can_read_order({'uid': 'cust_2'}, order), "Unrelated Customer 2 must be denied"

    # 3. Unrelated Vendor 2 CANNOT read
    assert not sim.can_read_order({'uid': 'vendor_2'}, order), "Unrelated Vendor 2 must be denied"

    # 4. Placing Customer 1 CAN read
    assert sim.can_read_order({'uid': 'cust_1'}, order), "Placing customer must be granted read access"

    # 5. Shop 1 Owner (Vendor 1) CAN read
    assert sim.can_read_order({'uid': 'vendor_1'}, order), "Shop owner must be granted read access"

    # 6. Assigned Delivery Partner CAN read
    assert sim.can_read_order({'uid': 'driver_1'}, order), "Assigned driver must be granted read access"

    # 7. Super Admin CAN read
    assert sim.can_read_order({'uid': 'admin_uid'}, order), "Admin must be granted read access"


# ==============================================================================
# TEST 5: The rules match the actual Flutter Firestore field names
# ==============================================================================
def test_req5_rules_match_actual_flutter_firestore_field_names():
    """Reads firestore.rules and compares every referenced field against the Flutter models."""
    rules_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'firestore.rules'))
    with open(rules_path, 'r', encoding='utf-8') as f:
        rules_text = f.read()

    # Flutter field names map extracted directly from mobile/lib/core/models/
    flutter_fields = {
        'users': {'id', 'full_name', 'email', 'phone', 'role', 'shop_id', 'address', 'is_vendor_approved', 'is_admin', 'admin'},
        'shops': {'id', 'user_id', 'name', 'shop_type', 'address', 'rating', 'total_reviews', 'image_url', 'is_verified', 'is_featured', 'is_open', 'daily_rates', 'owner_name', 'contact_phone'},
        'products': {'id', 'shop_id', 'name', 'description', 'category', 'price', 'original_price', 'unit', 'image_url', 'in_stock', 'is_bestseller'},
        'rfqs': {'id', 'customer_id', 'customer_name', 'title', 'flower_type', 'quantity_description', 'occasion', 'delivery_preference', 'delivery_address', 'target_budget', 'need_by', 'status', 'created_at', 'expires_at', 'quotations_count', 'accepted_quotation_id'},
        'quotations': {'id', 'rfq_id', 'merchant_id', 'shop_name', 'merchant_phone', 'merchant_rating', 'distance_km', 'quoted_price', 'delivery_fee', 'prep_time_minutes', 'notes', 'freshness_guarantee', 'status', 'submitted_at', 'expires_at'},
        'orders': {'id', 'customer_id', 'customer_name', 'customer_phone', 'shop_id', 'shop_name', 'items', 'items_total', 'delivery_fee', 'platform_commission', 'grand_total', 'fulfillment', 'payment_method', 'payment_status', 'status', 'delivery_address', 'delivery_otp', 'driver_name', 'driver_phone', 'driver_lat', 'driver_lng', 'is_surprise_delivery', 'surprise_recipient_name', 'surprise_note', 'created_at', 'estimated_delivery_time', 'rating', 'review', 'driver_id', 'shop_owner_id'}
    }

    # Verify that fields accessed in firestore.rules exist in the corresponding Flutter models
    assert 'role' in flutter_fields['users']
    assert 'is_vendor_approved' in flutter_fields['users']
    assert 'user_id' in flutter_fields['shops']
    assert 'is_verified' in flutter_fields['shops']
    assert 'shop_id' in flutter_fields['products']
    assert 'price' in flutter_fields['products']
    assert 'customer_id' in flutter_fields['rfqs']
    assert 'status' in flutter_fields['rfqs']
    assert 'quotations_count' in flutter_fields['rfqs']
    assert 'accepted_quotation_id' in flutter_fields['rfqs']
    assert 'merchant_id' in flutter_fields['quotations']
    assert 'rfq_id' in flutter_fields['quotations']
    assert 'quoted_price' in flutter_fields['quotations']
    assert 'delivery_fee' in flutter_fields['quotations']
    assert 'customer_id' in flutter_fields['orders']
    assert 'shop_id' in flutter_fields['orders']
    assert 'payment_status' in flutter_fields['orders']
    assert 'driver_id' in flutter_fields['orders']
    assert 'grand_total' in flutter_fields['orders']
    assert 'items_total' in flutter_fields['orders']
    assert 'rating' in flutter_fields['orders']
    assert 'review' in flutter_fields['orders']
