import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/rfq_model.dart';
import '../models/quotation_model.dart';
import '../models/order_model.dart';
import '../constants/demo_data.dart';
import '../services/firestore_service.dart';
import 'order_provider.dart';

class RFQState {
  final List<RFQModel> requests;
  final Map<String, List<QuotationModel>> quotationsMap; // rfqId -> List<QuotationModel>
  final String? activeRfqId;

  const RFQState({
    required this.requests,
    required this.quotationsMap,
    this.activeRfqId,
  });

  RFQState copyWith({
    List<RFQModel>? requests,
    Map<String, List<QuotationModel>>? quotationsMap,
    String? activeRfqId,
  }) {
    return RFQState(
      requests: requests ?? this.requests,
      quotationsMap: quotationsMap ?? this.quotationsMap,
      activeRfqId: activeRfqId ?? this.activeRfqId,
    );
  }
}

class RFQNotifier extends Notifier<RFQState> {
  final _uuid = const Uuid();

  @override
  RFQState build() {
    return RFQState(
      requests: [DemoData.initialRfq],
      quotationsMap: {
        DemoData.initialRfq.id: List.from(DemoData.initialQuotations),
      },
      activeRfqId: DemoData.initialRfq.id,
    );
  }

  void setActiveRfq(String rfqId) {
    state = state.copyWith(activeRfqId: rfqId);
  }

  RFQModel createRFQ({
    required String customerId,
    required String customerName,
    required String title,
    required String flowerType,
    required String quantityDescription,
    String? occasion,
    required DeliveryPreference deliveryPreference,
    required String deliveryAddress,
    double? targetBudget,
    required DateTime needBy,
  }) {
    final newId = 'rfq_${_uuid.v4().substring(0, 8)}';
    final newRfq = RFQModel(
      id: newId,
      customerId: customerId,
      customerName: customerName,
      title: title,
      flowerType: flowerType,
      quantityDescription: quantityDescription,
      occasion: occasion,
      deliveryPreference: deliveryPreference,
      deliveryAddress: deliveryAddress,
      targetBudget: targetBudget,
      needBy: needBy,
      status: RFQStatus.broadcasting,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 45)),
      quotationsCount: 0,
    );

    // Persist RFQ to Cloud Firestore
    try {
      FirestoreService.createRfq(newRfq);
    } catch (_) {}

    final updatedRequests = [newRfq, ...state.requests];
    final updatedQuotesMap = Map<String, List<QuotationModel>>.from(state.quotationsMap);
    updatedQuotesMap[newId] = [];

    state = state.copyWith(
      requests: updatedRequests,
      quotationsMap: updatedQuotesMap,
      activeRfqId: newId,
    );

    return newRfq;
  }

  void submitQuotation({
    required String rfqId,
    required String merchantId,
    String? shopId,
    required String shopName,
    required String merchantPhone,
    required double merchantRating,
    required double distanceKm,
    required double quotedPrice,
    required double deliveryFee,
    required int prepTimeMinutes,
    required String notes,
    required String freshnessGuarantee,
  }) {
    final quoteId = 'quote_${_uuid.v4().substring(0, 6)}';
    final newQuote = QuotationModel(
      id: quoteId,
      rfqId: rfqId,
      merchantId: merchantId,
      shopId: shopId ?? merchantId,
      shopName: shopName,
      merchantPhone: merchantPhone,
      merchantRating: merchantRating,
      distanceKm: distanceKm,
      quotedPrice: quotedPrice,
      deliveryFee: deliveryFee,
      prepTimeMinutes: prepTimeMinutes,
      notes: notes,
      freshnessGuarantee: freshnessGuarantee,
      status: QuotationStatus.pending,
      submittedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );

    // Persist Quotation to Cloud Firestore
    try {
      FirestoreService.submitQuotation(newQuote);
    } catch (_) {}

    final updatedQuotesMap = Map<String, List<QuotationModel>>.from(state.quotationsMap);
    final existingList = List<QuotationModel>.from(updatedQuotesMap[rfqId] ?? []);
    existingList.add(newQuote);
    updatedQuotesMap[rfqId] = existingList;

    final updatedRequests = state.requests.map((r) {
      if (r.id == rfqId) {
        return r.copyWith(
          status: RFQStatus.quotesReceived,
          quotationsCount: existingList.length,
        );
      }
      return r;
    }).toList();

    state = state.copyWith(
      requests: updatedRequests,
      quotationsMap: updatedQuotesMap,
    );
  }

  /// Customer accepts one quotation:
  /// - Locks the quotation as ACCEPTED
  /// - Marks all other quotations for this RFQ as REJECTED
  /// - Marks the RFQ as ACCEPTED
  /// - Creates a confirmed Order in the OrderNotifier
  OrderModel? acceptQuotation({
    required String rfqId,
    required String quotationId,
  }) {
    final quotes = state.quotationsMap[rfqId];
    if (quotes == null) return null;

    final chosenIndex = quotes.indexWhere((q) => q.id == quotationId);
    if (chosenIndex < 0) return null;

    final chosen = quotes[chosenIndex];
    final updatedQuotes = quotes.map((q) {
      if (q.id == quotationId) {
        return q.copyWith(status: QuotationStatus.accepted);
      } else {
        return q.copyWith(status: QuotationStatus.rejected);
      }
    }).toList();

    final updatedQuotesMap = Map<String, List<QuotationModel>>.from(state.quotationsMap);
    updatedQuotesMap[rfqId] = updatedQuotes;

    final rfqIndex = state.requests.indexWhere((r) => r.id == rfqId);
    if (rfqIndex < 0) return null;
    final rfq = state.requests[rfqIndex];

    final updatedRequests = List<RFQModel>.from(state.requests);
    updatedRequests[rfqIndex] = rfq.copyWith(
      status: RFQStatus.accepted,
      acceptedQuotationId: quotationId,
    );

    // Persist accepted status to Cloud Firestore
    try {
      FirestoreService.acceptQuotation(rfqId, quotationId);
    } catch (_) {}

    state = state.copyWith(
      requests: updatedRequests,
      quotationsMap: updatedQuotesMap,
    );

    // Convert into a real confirmed persistent order
    final newOrder = OrderModel(
      id: 'ORD-Q${_uuid.v4().substring(0, 6).toUpperCase()}',
      customerId: rfq.customerId,
      customerName: rfq.customerName,
      customerPhone: '+91 98765 43210',
      shopId: chosen.shopId ?? chosen.merchantId,
      shopName: chosen.shopName,
      items: [
        OrderItemModel(
          productId: 'custom_${rfq.id}',
          productName: '${rfq.flowerType} (${rfq.quantityDescription})',
          unitPrice: chosen.quotedPrice,
          quantity: 1,
          unit: 'Custom Quotation',
          imageUrl: 'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=600&q=80',
        ),
      ],
      itemsTotal: chosen.quotedPrice,
      deliveryFee: rfq.deliveryPreference == DeliveryPreference.homeDelivery
          ? chosen.deliveryFee
          : 0.0,
      platformCommission: chosen.quotedPrice * 0.10,
      grandTotal: chosen.quotedPrice +
          (rfq.deliveryPreference == DeliveryPreference.homeDelivery
              ? chosen.deliveryFee
              : 0.0),
      fulfillment: rfq.deliveryPreference == DeliveryPreference.homeDelivery
          ? OrderFulfillment.homeDelivery
          : OrderFulfillment.selfPickup,
      paymentMethod: PaymentMethod.upi,
      paymentStatus: PaymentStatus.pending, // Pending customer payment completion
      status: OrderStatus.confirmed,
      deliveryAddress: rfq.deliveryAddress,
      deliveryOtp: '7412',
      driverName: null, // Driver unassigned until order dispatch
      driverPhone: null,
      driverLat: null,
      driverLng: null,
      createdAt: DateTime.now(),
      estimatedDeliveryTime: DateTime.now().add(Duration(minutes: chosen.prepTimeMinutes + 20)),
    );

    ref.read(orderProvider.notifier).addOrder(newOrder);
    return newOrder;
  }

  /// Reload persistent RFQs and quotations from Cloud Firestore
  Future<void> refreshFromFirestore({String? customerId}) async {
    try {
      final firestoreRfqs = await FirestoreService.getRfqs(customerId: customerId);
      if (firestoreRfqs != null && firestoreRfqs.isNotEmpty) {
        final updatedQuotesMap = Map<String, List<QuotationModel>>.from(state.quotationsMap);
        for (final rfq in firestoreRfqs) {
          final quotes = await FirestoreService.getQuotationsForRfq(rfq.id);
          if (quotes != null) {
            updatedQuotesMap[rfq.id] = quotes;
          }
        }
        final existingIds = state.requests.map((r) => r.id).toSet();
        final List<RFQModel> newRfqs = [];
        for (final r in firestoreRfqs) {
          if (!existingIds.contains(r.id)) {
            newRfqs.add(r);
          }
        }
        state = state.copyWith(
          requests: [...newRfqs, ...state.requests],
          quotationsMap: updatedQuotesMap,
        );
      }
    } catch (_) {}
  }
}

final rfqProvider = NotifierProvider<RFQNotifier, RFQState>(() {
  return RFQNotifier();
});

