const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc } = require('firebase/firestore');

const PROJECT_ID = 'flowerconnect-emulator-test';

describe('Official Firebase Firestore Security Rules Engine Tests', function () {
  this.timeout(20000);
  let testEnv;

  before(async () => {
    const rules = fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8');
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: rules,
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();

    // Seed trusted system state using security-rules-disabled context
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      // Seed Super Admin
      await setDoc(doc(db, 'users', 'admin_uid'), {
        id: 'admin_uid',
        role: 'ADMIN',
        is_vendor_approved: true,
        full_name: 'Super Admin',
      });

      // Seed Customer 1 & Customer 2
      await setDoc(doc(db, 'users', 'cust_1'), {
        id: 'cust_1',
        role: 'customer',
        is_vendor_approved: false,
        full_name: 'Customer One',
      });
      await setDoc(doc(db, 'users', 'cust_2'), {
        id: 'cust_2',
        role: 'customer',
        is_vendor_approved: false,
        full_name: 'Customer Two',
      });

      // Seed Approved Vendor 1 with Shop 1
      await setDoc(doc(db, 'users', 'vendor_1'), {
        id: 'vendor_1',
        role: 'flowerMerchant',
        is_vendor_approved: true,
        shop_id: 'shop_1',
        full_name: 'Vendor One',
      });
      await setDoc(doc(db, 'shops', 'shop_1'), {
        id: 'shop_1',
        user_id: 'vendor_1',
        is_verified: true,
        name: 'Vendor 1 Flower Stall',
      });

      // Seed Approved Vendor 2 with Shop 2
      await setDoc(doc(db, 'users', 'vendor_2'), {
        id: 'vendor_2',
        role: 'flowerMerchant',
        is_vendor_approved: true,
        shop_id: 'shop_2',
        full_name: 'Vendor Two',
      });
      await setDoc(doc(db, 'shops', 'shop_2'), {
        id: 'shop_2',
        user_id: 'vendor_2',
        is_verified: true,
        name: 'Vendor 2 Flora',
      });

      // Seed Unapproved Pending Vendor with Pending Shop
      await setDoc(doc(db, 'users', 'vendor_unapproved'), {
        id: 'vendor_unapproved',
        role: 'flowerMerchant',
        is_vendor_approved: false,
        full_name: 'Pending Vendor',
      });
      await setDoc(doc(db, 'shops', 'shop_pending'), {
        id: 'shop_pending',
        user_id: 'vendor_unapproved',
        is_verified: false,
        name: 'Pending Stall',
      });

      // Seed Product 1 owned by Shop 1
      await setDoc(doc(db, 'products', 'prod_1'), {
        id: 'prod_1',
        shop_id: 'shop_1',
        name: 'Red Roses Bouquet',
        price: 350.0,
      });

      // Seed RFQ 1 owned by Customer 1
      await setDoc(doc(db, 'rfqs', 'rfq_1'), {
        id: 'rfq_1',
        customer_id: 'cust_1',
        status: 'broadcasting',
        flower_type: 'Roses',
        target_budget: 1000.0,
      });

      // Seed Quotation 1 submitted by Vendor 1 for RFQ 1
      await setDoc(doc(db, 'quotations', 'quote_1'), {
        id: 'quote_1',
        rfq_id: 'rfq_1',
        merchant_id: 'vendor_1',
        quoted_price: 850.0,
        delivery_fee: 40.0,
        status: 'pending',
      });

      // Seed Order 1 placed by Customer 1 at Shop 1
      await setDoc(doc(db, 'orders', 'ord_1'), {
        id: 'ord_1',
        customer_id: 'cust_1',
        shop_id: 'shop_1',
        grand_total: 500.0,
        items_total: 460.0,
        delivery_fee: 40.0,
        payment_status: 'pending',
        status: 'placed',
      });
    });
  });

  // ---------------------------------------------------------------------------
  // 1. ADMIN ROLE & VENDOR APPROVAL PROTECTION
  // ---------------------------------------------------------------------------
  describe('1. Admin Role & Vendor Approval Protection', () => {
    it('Customer cannot self-assign role=ADMIN on creation', async () => {
      const custDb = testEnv.authenticatedContext('attacker_user').firestore();
      await assertFails(
        setDoc(doc(custDb, 'users', 'attacker_user'), {
          id: 'attacker_user',
          role: 'ADMIN',
          full_name: 'Malicious User',
        })
      );
    });

    it('Customer cannot self-assign role=admin or SUPER_ADMIN on creation', async () => {
      const custDb = testEnv.authenticatedContext('attacker_user2').firestore();
      await assertFails(
        setDoc(doc(custDb, 'users', 'attacker_user2'), {
          id: 'attacker_user2',
          role: 'admin',
          full_name: 'Malicious User',
        })
      );
      await assertFails(
        setDoc(doc(custDb, 'users', 'attacker_user2'), {
          id: 'attacker_user2',
          role: 'SUPER_ADMIN',
          full_name: 'Malicious User',
        })
      );
    });

    it('Customer cannot self-approve as vendor (is_vendor_approved=true) on creation', async () => {
      const custDb = testEnv.authenticatedContext('attacker_user3').firestore();
      await assertFails(
        setDoc(doc(custDb, 'users', 'attacker_user3'), {
          id: 'attacker_user3',
          role: 'flowerMerchant',
          is_vendor_approved: true,
          full_name: 'Sneaky Merchant',
        })
      );
    });

    it('Customer cannot set is_admin=true on creation', async () => {
      const custDb = testEnv.authenticatedContext('attacker_user4').firestore();
      await assertFails(
        setDoc(doc(custDb, 'users', 'attacker_user4'), {
          id: 'attacker_user4',
          role: 'customer',
          is_admin: true,
          full_name: 'Sneaky Customer',
        })
      );
    });

    it('Legitimate customer profile creation succeeds with is_vendor_approved=false', async () => {
      const custDb = testEnv.authenticatedContext('new_legit_cust').firestore();
      await assertSucceeds(
        setDoc(doc(custDb, 'users', 'new_legit_cust'), {
          id: 'new_legit_cust',
          role: 'customer',
          is_vendor_approved: false,
          full_name: 'Legit Customer',
        })
      );
    });

    it('Customer cannot escalate role to ADMIN on profile update', async () => {
      const custDb = testEnv.authenticatedContext('cust_1').firestore();
      await assertFails(
        updateDoc(doc(custDb, 'users', 'cust_1'), {
          role: 'ADMIN',
        })
      );
    });

    it('Customer/Vendor cannot self-approve vendor status on update', async () => {
      const vendDb = testEnv.authenticatedContext('vendor_unapproved').firestore();
      await assertFails(
        updateDoc(doc(vendDb, 'users', 'vendor_unapproved'), {
          is_vendor_approved: true,
        })
      );
    });

    it('Super Admin CAN approve a vendor on update', async () => {
      const adminDb = testEnv.authenticatedContext('admin_uid', { admin: true }).firestore();
      await assertSucceeds(
        updateDoc(doc(adminDb, 'users', 'vendor_unapproved'), {
          is_vendor_approved: true,
        })
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 2. SHOP SPOOFING & VENDOR APPROVAL
  // ---------------------------------------------------------------------------
  describe('2. Shop Spoofing & Verification Protection', () => {
    it('User cannot create a shop with another user ID', async () => {
      const userDb = testEnv.authenticatedContext('attacker_uid').firestore();
      await assertFails(
        setDoc(doc(userDb, 'shops', 'fake_shop_1'), {
          id: 'fake_shop_1',
          user_id: 'victim_uid',
          is_verified: false,
          name: 'Fake Shop',
        })
      );
    });

    it('User cannot create a pre-verified shop (is_verified=true)', async () => {
      const userDb = testEnv.authenticatedContext('attacker_uid').firestore();
      await assertFails(
        setDoc(doc(userDb, 'shops', 'fake_shop_2'), {
          id: 'fake_shop_2',
          user_id: 'attacker_uid',
          is_verified: true,
          name: 'Self Verified Shop',
        })
      );
    });

    it('User CAN create an unverified shop with own user_id', async () => {
      const userDb = testEnv.authenticatedContext('legit_merchant_new').firestore();
      await assertSucceeds(
        setDoc(doc(userDb, 'shops', 'new_shop_legit'), {
          id: 'new_shop_legit',
          user_id: 'legit_merchant_new',
          is_verified: false,
          name: 'Fresh Flowers',
        })
      );
    });

    it('Shop owner cannot self-verify shop on update', async () => {
      const vendDb = testEnv.authenticatedContext('vendor_unapproved').firestore();
      await assertFails(
        updateDoc(doc(vendDb, 'shops', 'shop_pending'), {
          is_verified: true,
        })
      );
    });

    it('Shop owner CAN update rates and shop details', async () => {
      const vendDb = testEnv.authenticatedContext('vendor_1').firestore();
      await assertSucceeds(
        updateDoc(doc(vendDb, 'shops', 'shop_1'), {
          daily_rates: { Jasmine: 400.0 },
        })
      );
    });

    it('Admin CAN approve and verify shop', async () => {
      const adminDb = testEnv.authenticatedContext('admin_uid', { admin: true }).firestore();
      await assertSucceeds(
        updateDoc(doc(adminDb, 'shops', 'shop_pending'), {
          is_verified: true,
          is_open: true,
        })
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 3. VENDOR PRODUCT & QUOTATION ISOLATION
  // ---------------------------------------------------------------------------
  describe('3. Vendor Product & Quotation Isolation', () => {
    it('Unapproved vendor cannot create products', async () => {
      const unappDb = testEnv.authenticatedContext('vendor_unapproved').firestore();
      await assertFails(
        setDoc(doc(unappDb, 'products', 'unapp_prod'), {
          id: 'unapp_prod',
          shop_id: 'shop_pending',
          name: 'Illegal Product',
          price: 100.0,
        })
      );
    });

    it('Vendor 2 cannot create a product under Vendor 1 shop_id', async () => {
      const v2Db = testEnv.authenticatedContext('vendor_2').firestore();
      await assertFails(
        setDoc(doc(v2Db, 'products', 'v2_in_v1_shop'), {
          id: 'v2_in_v1_shop',
          shop_id: 'shop_1',
          name: 'Stolen Shop Product',
          price: 200.0,
        })
      );
    });

    it('Vendor 1 CAN create a product in their own shop', async () => {
      const v1Db = testEnv.authenticatedContext('vendor_1').firestore();
      await assertSucceeds(
        setDoc(doc(v1Db, 'products', 'new_v1_prod'), {
          id: 'new_v1_prod',
          shop_id: 'shop_1',
          name: 'White Lilies',
          price: 250.0,
        })
      );
    });

    it('Vendor 2 CANNOT edit Vendor 1 product (price sabotage)', async () => {
      const v2Db = testEnv.authenticatedContext('vendor_2').firestore();
      await assertFails(
        updateDoc(doc(v2Db, 'products', 'prod_1'), {
          price: 1.0,
        })
      );
    });

    it('Vendor 2 CANNOT delete Vendor 1 product', async () => {
      const v2Db = testEnv.authenticatedContext('vendor_2').firestore();
      await assertFails(deleteDoc(doc(v2Db, 'products', 'prod_1')));
    });

    it('Vendor 1 CAN edit their own product', async () => {
      const v1Db = testEnv.authenticatedContext('vendor_1').firestore();
      await assertSucceeds(
        updateDoc(doc(v1Db, 'products', 'prod_1'), {
          price: 380.0,
        })
      );
    });

    it('Vendor 2 CANNOT read Vendor 1 sealed quotation bid', async () => {
      const v2Db = testEnv.authenticatedContext('vendor_2').firestore();
      await assertFails(getDoc(doc(v2Db, 'quotations', 'quote_1')));
    });

    it('Vendor 2 CANNOT modify Vendor 1 quotation bid', async () => {
      const v2Db = testEnv.authenticatedContext('vendor_2').firestore();
      await assertFails(
        updateDoc(doc(v2Db, 'quotations', 'quote_1'), {
          quoted_price: 9999.0,
        })
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 4. QUOTATION TAMPERING & ACCEPTANCE
  // ---------------------------------------------------------------------------
  describe('4. Quotation Tampering & Acceptance Protection', () => {
    it('Customer CAN read quotations submitted for their own RFQ', async () => {
      const custDb = testEnv.authenticatedContext('cust_1').firestore();
      await assertSucceeds(getDoc(doc(custDb, 'quotations', 'quote_1')));
    });

    it('Unrelated Customer 2 CANNOT read quotations for Customer 1 RFQ', async () => {
      const cust2Db = testEnv.authenticatedContext('cust_2').firestore();
      await assertFails(getDoc(doc(cust2Db, 'quotations', 'quote_1')));
    });

    it('Customer CANNOT modify quoted_price when accepting quotation', async () => {
      const custDb = testEnv.authenticatedContext('cust_1').firestore();
      await assertFails(
        updateDoc(doc(custDb, 'quotations', 'quote_1'), {
          status: 'accepted',
          quoted_price: 10.0,
        })
      );
    });

    it('Customer CANNOT modify delivery_fee when accepting quotation', async () => {
      const custDb = testEnv.authenticatedContext('cust_1').firestore();
      await assertFails(
        updateDoc(doc(custDb, 'quotations', 'quote_1'), {
          status: 'accepted',
          delivery_fee: 0.0,
        })
      );
    });

    it('Customer CAN legitimately accept quotation (status only)', async () => {
      const custDb = testEnv.authenticatedContext('cust_1').firestore();
      await assertSucceeds(
        updateDoc(doc(custDb, 'quotations', 'quote_1'), {
          status: 'accepted',
        })
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 5. PRIVATE ORDER ACCESS & FINANCIAL / DRIVER SECURITY
  // ---------------------------------------------------------------------------
  describe('5. Private Order Access & Financial / Driver Security', () => {
    it('Unauthenticated user CANNOT read private order', async () => {
      const unauthDb = testEnv.unauthenticatedContext().firestore();
      await assertFails(getDoc(doc(unauthDb, 'orders', 'ord_1')));
    });

    it('Customer 2 CANNOT read Customer 1 private order', async () => {
      const cust2Db = testEnv.authenticatedContext('cust_2').firestore();
      await assertFails(getDoc(doc(cust2Db, 'orders', 'ord_1')));
    });

    it('Vendor 2 CANNOT read order placed at Vendor 1 shop', async () => {
      const v2Db = testEnv.authenticatedContext('vendor_2').firestore();
      await assertFails(getDoc(doc(v2Db, 'orders', 'ord_1')));
    });

    it('Placing Customer 1 CAN read their own order', async () => {
      const cust1Db = testEnv.authenticatedContext('cust_1').firestore();
      await assertSucceeds(getDoc(doc(cust1Db, 'orders', 'ord_1')));
    });

    it('Shop 1 Owner (Vendor 1) CAN read order placed at their shop', async () => {
      const v1Db = testEnv.authenticatedContext('vendor_1').firestore();
      await assertSucceeds(getDoc(doc(v1Db, 'orders', 'ord_1')));
    });

    it('Customer CANNOT create order with payment_status=paid', async () => {
      const custDb = testEnv.authenticatedContext('cust_1').firestore();
      await assertFails(
        setDoc(doc(custDb, 'orders', 'ord_bypass_paid'), {
          id: 'ord_bypass_paid',
          customer_id: 'cust_1',
          shop_id: 'shop_1',
          grand_total: 500.0,
          items_total: 460.0,
          payment_status: 'paid',
          status: 'placed',
        })
      );
    });

    it('Customer CANNOT create order with pre-assigned driver', async () => {
      const custDb = testEnv.authenticatedContext('cust_1').firestore();
      await assertFails(
        setDoc(doc(custDb, 'orders', 'ord_fake_driver'), {
          id: 'ord_fake_driver',
          customer_id: 'cust_1',
          shop_id: 'shop_1',
          grand_total: 500.0,
          items_total: 460.0,
          payment_status: 'pending',
          driver_name: 'Fake Driver',
          status: 'placed',
        })
      );
    });

    it('Customer CAN create order with pending payment & unassigned driver', async () => {
      const custDb = testEnv.authenticatedContext('cust_1').firestore();
      await assertSucceeds(
        setDoc(doc(custDb, 'orders', 'ord_legit_2'), {
          id: 'ord_legit_2',
          customer_id: 'cust_1',
          shop_id: 'shop_1',
          grand_total: 500.0,
          items_total: 460.0,
          payment_status: 'pending',
          status: 'placed',
        })
      );
    });

    it('Customer CANNOT change payment_status to paid on update', async () => {
      const custDb = testEnv.authenticatedContext('cust_1').firestore();
      await assertFails(
        updateDoc(doc(custDb, 'orders', 'ord_1'), {
          payment_status: 'paid',
        })
      );
    });

    it('Customer CANNOT reduce grand_total on update', async () => {
      const custDb = testEnv.authenticatedContext('cust_1').firestore();
      await assertFails(
        updateDoc(doc(custDb, 'orders', 'ord_1'), {
          grand_total: 10.0,
        })
      );
    });

    it('Vendor CAN progress order status (confirmed, preparing)', async () => {
      const v1Db = testEnv.authenticatedContext('vendor_1').firestore();
      await assertSucceeds(
        updateDoc(doc(v1Db, 'orders', 'ord_1'), {
          status: 'confirmed',
        })
      );
      await assertSucceeds(
        updateDoc(doc(v1Db, 'orders', 'ord_1'), {
          status: 'preparing',
        })
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 6. RFQ PRIVACY
  // ---------------------------------------------------------------------------
  describe('6. RFQ Privacy Protection', () => {
    it('Customer 1 CAN read their own RFQ', async () => {
      const custDb = testEnv.authenticatedContext('cust_1').firestore();
      await assertSucceeds(getDoc(doc(custDb, 'rfqs', 'rfq_1')));
    });

    it('Customer 2 CANNOT read Customer 1 RFQ', async () => {
      const cust2Db = testEnv.authenticatedContext('cust_2').firestore();
      await assertFails(getDoc(doc(cust2Db, 'rfqs', 'rfq_1')));
    });

    it('Approved Vendor 1 CAN read RFQ to submit quotations', async () => {
      const v1Db = testEnv.authenticatedContext('vendor_1').firestore();
      await assertSucceeds(getDoc(doc(v1Db, 'rfqs', 'rfq_1')));
    });

    it('Unapproved Vendor CANNOT read RFQ', async () => {
      const unappDb = testEnv.authenticatedContext('vendor_unapproved').firestore();
      await assertFails(getDoc(doc(unappDb, 'rfqs', 'rfq_1')));
    });
  });
});
