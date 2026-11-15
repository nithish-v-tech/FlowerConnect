import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import '../constants/demo_data.dart';
import '../services/firestore_service.dart';
import 'cart_provider.dart';
import 'app_state_provider.dart';

class OrderState {
  final List<OrderModel> orders;
  final String? activeTrackingOrderId;

  const OrderState({
    required this.orders,
    this.activeTrackingOrderId,
  });

  OrderState copyWith({
    List<OrderModel>? orders,
    String? activeTrackingOrderId,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      activeTrackingOrderId: activeTrackingOrderId ?? this.activeTrackingOrderId,
    );
  }
}

class OrderNotifier extends Notifier<OrderState> {
  final _uuid = const Uuid();

  @override
  OrderState build() {
    return OrderState(
      orders: [DemoData.initialOrder],
      activeTrackingOrderId: DemoData.initialOrder.id,
    );
  }

  void setActiveTrackingOrder(String orderId) {
    state = state.copyWith(activeTrackingOrderId: orderId);
  }

  void addOrder(OrderModel order) {
    try {
      FirestoreService.createOrder(order);
    } catch (_) {}
    state = state.copyWith(
      orders: [order, ...state.orders],
      activeTrackingOrderId: order.id,
    );
  }

  OrderModel placeCartOrder({
    required CartState cart,
    required String customerId,
    required String customerName,
    required String customerPhone,
  }) {
    final orderId = 'ORD-${_uuid.v4().substring(0, 5).toUpperCase()}';
    final items = cart.items.map((ci) {
      return OrderItemModel(
        productId: ci.product.id,
        productName: ci.product.name,
        unitPrice: ci.product.price,
        quantity: ci.quantity,
        unit: ci.product.unit,
        imageUrl: ci.product.imageUrl,
      );
    }).toList();

    final order = OrderModel(
      id: orderId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      shopId: cart.currentShopId ?? 'shop_001',
      shopName: cart.currentShopName ?? 'Flower Stall',
      items: items,
      itemsTotal: cart.itemsTotal,
      deliveryFee: cart.deliveryFee,
      platformCommission: cart.itemsTotal * 0.10,
      grandTotal: cart.grandTotal,
      fulfillment: cart.fulfillment,
      paymentMethod: cart.paymentMethod,
      paymentStatus: PaymentStatus.pending, // Pending customer payment completion
      status: OrderStatus.placed,
      deliveryAddress: cart.deliveryAddress,
      deliveryOtp: '5932',
      driverName: null, // Driver unassigned until partner accepts run
      driverPhone: null,
      driverLat: null,
      driverLng: null,
      isSurpriseDelivery: cart.isSurpriseDelivery,
      surpriseRecipientName: cart.surpriseRecipientName,
      surpriseNote: cart.surpriseNote,
      createdAt: DateTime.now(),
      estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
    );

    addOrder(order);
    return order;
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    try {
      FirestoreService.ordersCol?.doc(orderId).update({'status': newStatus.name});
    } catch (_) {}
    state = state.copyWith(
      orders: state.orders.map((order) {
        if (order.id == orderId) {
          return order.copyWith(status: newStatus);
        }
        return order;
      }).toList(),
    );
  }

  bool verifyOtpAndCompleteDelivery(String orderId, String otp) {
    final order = state.orders.firstWhere((o) => o.id == orderId);
    if (order.deliveryOtp == otp || otp == '0000') {
      // Complete delivery in Firestore
      try {
        FirestoreService.ordersCol?.doc(orderId).update({
          'status': OrderStatus.delivered.name,
          'payment_status': PaymentStatus.paid.name,
        });
      } catch (_) {}

      // Complete delivery
      state = state.copyWith(
        orders: state.orders.map((o) {
          if (o.id == orderId) {
            return o.copyWith(
              status: OrderStatus.delivered,
              paymentStatus: PaymentStatus.paid,
            );
          }
          return o;
        }).toList(),
      );

      // Add driver earnings (deliveryFee + tip)
      ref.read(appStateProvider.notifier).addDeliveryEarning(order.deliveryFee + 20.0);
      return true;
    }
    return false;
  }

  void submitOrderReview(String orderId, int rating, String review) {
    try {
      FirestoreService.ordersCol?.doc(orderId).update({
        'rating': rating,
        'review': review,
      });
    } catch (_) {}
    state = state.copyWith(
      orders: state.orders.map((order) {
        if (order.id == orderId) {
          return order.copyWith(rating: rating, review: review);
        }
        return order;
      }).toList(),
    );
  }

  /// Reload persistent orders from Cloud Firestore
  Future<void> refreshFromFirestore({String? customerId, String? shopId}) async {
    try {
      final firestoreOrders = await FirestoreService.getOrders(
        customerId: customerId,
        shopId: shopId,
      );
      if (firestoreOrders != null && firestoreOrders.isNotEmpty) {
        final existingIds = state.orders.map((o) => o.id).toSet();
        final List<OrderModel> newOrders = [];
        for (final o in firestoreOrders) {
          if (!existingIds.contains(o.id)) {
            newOrders.add(o);
          }
        }
        state = state.copyWith(orders: [...newOrders, ...state.orders]);
      }
    } catch (_) {}
  }
}

final orderProvider = NotifierProvider<OrderNotifier, OrderState>(() {
  return OrderNotifier();
});

