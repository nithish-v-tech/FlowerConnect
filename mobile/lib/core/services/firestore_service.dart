import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/rfq_model.dart';
import '../models/quotation_model.dart';
import '../constants/demo_data.dart';

class FirestoreService {
  static FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // Collection references
  static CollectionReference? get usersCol => _firestore?.collection('users');
  static CollectionReference? get shopsCol => _firestore?.collection('shops');
  static CollectionReference? get productsCol => _firestore?.collection('products');
  static CollectionReference? get ordersCol => _firestore?.collection('orders');
  static CollectionReference? get rfqsCol => _firestore?.collection('rfqs');
  static CollectionReference? get quotationsCol => _firestore?.collection('quotations');

  /// Fetch user profile from Firestore users collection
  static Future<UserModel?> getUserProfile(String uid) async {
    final col = usersCol;
    if (col == null) return null;
    try {
      final doc = await col.doc(uid).get().timeout(const Duration(seconds: 4));
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[FirestoreService] getUserProfile fallback: $e');
    }
    return null;
  }

  /// Save or update user profile in Firestore
  static Future<void> saveUserProfile(UserModel user) async {
    final col = usersCol;
    if (col == null) return;
    try {
      await col.doc(user.id).set(user.toJson(), SetOptions(merge: true));
      debugPrint('[FirestoreService] Saved user profile: ${user.id} (${user.role.name})');
    } catch (e) {
      debugPrint('[FirestoreService] saveUserProfile error: $e');
    }
  }

  /// Fetch all shops from Firestore
  static Future<List<ShopModel>?> getShops() async {
    final col = shopsCol;
    if (col == null) return null;
    try {
      final snapshot = await col.get().timeout(const Duration(seconds: 4));
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((d) => ShopModel.fromJson(d.data() as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[FirestoreService] getShops fallback: $e');
    }
    return null;
  }

  /// Fetch products from Firestore
  static Future<List<ProductModel>?> getProducts({String? shopId}) async {
    final col = productsCol;
    if (col == null) return null;
    try {
      Query query = col;
      if (shopId != null) {
        query = query.where('shop_id', isEqualTo: shopId);
      }
      final snapshot = await query.get().timeout(const Duration(seconds: 4));
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((d) => ProductModel.fromJson(d.data() as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[FirestoreService] getProducts fallback: $e');
    }
    return null;
  }

  /// Admin approves vendor in Firestore
  static Future<bool> approveVendor(String shopId) async {
    final sCol = shopsCol;
    final uCol = usersCol;
    if (sCol == null || uCol == null) return false;
    try {
      // 1. Update shop document
      await sCol.doc(shopId).update({
        'is_verified': true,
        'is_open': true,
      });

      // 2. Update associated vendor user document
      final userSnapshot = await uCol.where('shop_id', isEqualTo: shopId).get();
      for (var doc in userSnapshot.docs) {
        await doc.reference.update({
          'is_vendor_approved': true,
        });
      }

      debugPrint('[FirestoreService] Shop $shopId successfully approved in Firestore!');
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] approveVendor error: $e');
      return false;
    }
  }

  /// Create or update order in Firestore
  static Future<void> createOrder(OrderModel order) async {
    final col = ordersCol;
    if (col == null) return;
    try {
      await col.doc(order.id).set(order.toJson());
      debugPrint('[FirestoreService] Order ${order.id} saved to Firestore');
    } catch (e) {
      debugPrint('[FirestoreService] createOrder error: $e');
    }
  }

  /// Fetch persistent orders from Firestore
  static Future<List<OrderModel>?> getOrders({String? customerId, String? shopId}) async {
    final col = ordersCol;
    if (col == null) return null;
    try {
      Query query = col;
      if (customerId != null) {
        query = query.where('customer_id', isEqualTo: customerId);
      }
      if (shopId != null) {
        query = query.where('shop_id', isEqualTo: shopId);
      }
      final snapshot = await query.get().timeout(const Duration(seconds: 4));
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((d) => OrderModel.fromJson(d.data() as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[FirestoreService] getOrders error: $e');
    }
    return null;
  }

  /// Broadcast a Custom RFQ to Cloud Firestore
  static Future<void> createRfq(RFQModel rfq) async {
    final col = rfqsCol;
    if (col == null) return;
    try {
      await col.doc(rfq.id).set(rfq.toJson());
      debugPrint('[FirestoreService] RFQ ${rfq.id} broadcasted to Firestore');
    } catch (e) {
      debugPrint('[FirestoreService] createRfq error: $e');
    }
  }

  /// Fetch active RFQs from Firestore
  static Future<List<RFQModel>?> getRfqs({String? customerId}) async {
    final col = rfqsCol;
    if (col == null) return null;
    try {
      Query query = col;
      if (customerId != null) {
        query = query.where('customer_id', isEqualTo: customerId);
      }
      final snapshot = await query.get().timeout(const Duration(seconds: 4));
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((d) => RFQModel.fromJson(d.data() as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[FirestoreService] getRfqs error: $e');
    }
    return null;
  }

  /// Submit a Vendor Quotation for an RFQ
  static Future<void> submitQuotation(QuotationModel quotation) async {
    final col = quotationsCol;
    final rCol = rfqsCol;
    if (col == null) return;
    try {
      await col.doc(quotation.id).set(quotation.toJson());
      // Increment quotations count on RFQ
      if (rCol != null) {
        await rCol.doc(quotation.rfqId).update({
          'quotations_count': FieldValue.increment(1),
          'status': RFQStatus.quotesReceived.name,
        });
      }
      debugPrint('[FirestoreService] Quotation ${quotation.id} submitted for RFQ ${quotation.rfqId}');
    } catch (e) {
      debugPrint('[FirestoreService] submitQuotation error: $e');
    }
  }

  /// Fetch quotations for a specific RFQ from Firestore
  static Future<List<QuotationModel>?> getQuotationsForRfq(String rfqId) async {
    final col = quotationsCol;
    if (col == null) return null;
    try {
      final snapshot = await col
          .where('rfq_id', isEqualTo: rfqId)
          .get()
          .timeout(const Duration(seconds: 4));
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((d) => QuotationModel.fromJson(d.data() as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[FirestoreService] getQuotationsForRfq error: $e');
    }
    return null;
  }

  /// Accept a Quotation for an RFQ and lock competing quotes
  static Future<void> acceptQuotation(String rfqId, String quotationId) async {
    final rCol = rfqsCol;
    final qCol = quotationsCol;
    if (rCol == null || qCol == null) return;
    try {
      await rCol.doc(rfqId).update({
        'status': RFQStatus.accepted.name,
        'accepted_quotation_id': quotationId,
      });

      // Mark chosen as accepted and lock others as rejected
      final allQuotes = await qCol.where('rfq_id', isEqualTo: rfqId).get();
      for (var doc in allQuotes.docs) {
        if (doc.id == quotationId) {
          await doc.reference.update({'status': QuotationStatus.accepted.name});
        } else {
          await doc.reference.update({'status': QuotationStatus.rejected.name});
        }
      }
      debugPrint('[FirestoreService] Quotation $quotationId accepted and locked for RFQ $rfqId');
    } catch (e) {
      debugPrint('[FirestoreService] acceptQuotation error: $e');
    }
  }

  /// Seed initial Firestore data if collections are empty (Free & Automatic)
  static Future<void> seedInitialDataIfEmpty() async {
    final col = shopsCol;
    final pCol = productsCol;
    if (col == null || pCol == null) return;
    try {
      final shopsSnapshot = await col.limit(1).get().timeout(const Duration(seconds: 3));
      if (shopsSnapshot.docs.isEmpty) {
        debugPrint('[FirestoreService] Firestore is empty. Seeding initial flower marketplace data...');

        // 1. Seed shops
        for (var shop in DemoData.shops) {
          await col.doc(shop.id).set(shop.toJson());
        }

        // 2. Seed catalogue products
        for (var product in DemoData.products) {
          await pCol.doc(product.id).set(product.toJson());
        }

        debugPrint('[FirestoreService] Seeding complete! ${DemoData.shops.length} shops & ${DemoData.products.length} products written.');
      }
    } catch (e) {
      debugPrint('[FirestoreService] seedInitialDataIfEmpty skipped or offline: $e');
    }
  }
}
