import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

class CartItem {
  final ProductModel product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    ProductModel? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartState {
  final List<CartItem> items;
  final OrderFulfillment fulfillment;
  final PaymentMethod paymentMethod;
  final String deliveryAddress;
  final bool isSurpriseDelivery;
  final String surpriseRecipientName;
  final String surpriseNote;

  const CartState({
    this.items = const [],
    this.fulfillment = OrderFulfillment.homeDelivery,
    this.paymentMethod = PaymentMethod.upi,
    this.deliveryAddress = 'Flat 402, Oakwood Heights, 12th Main Indiranagar, Bengaluru',
    this.isSurpriseDelivery = false,
    this.surpriseRecipientName = '',
    this.surpriseNote = '',
  });

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get itemsTotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get deliveryFee =>
      (fulfillment == OrderFulfillment.selfPickup || items.isEmpty) ? 0.0 : 40.0;

  double get platformFee => items.isEmpty ? 0.0 : 15.0;

  double get grandTotal => itemsTotal + deliveryFee + platformFee;

  String? get currentShopId => items.isEmpty ? null : items.first.product.shopId;
  String? get currentShopName => items.isEmpty ? null : items.first.product.shopName;

  CartState copyWith({
    List<CartItem>? items,
    OrderFulfillment? fulfillment,
    PaymentMethod? paymentMethod,
    String? deliveryAddress,
    bool? isSurpriseDelivery,
    String? surpriseRecipientName,
    String? surpriseNote,
  }) {
    return CartState(
      items: items ?? this.items,
      fulfillment: fulfillment ?? this.fulfillment,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      isSurpriseDelivery: isSurpriseDelivery ?? this.isSurpriseDelivery,
      surpriseRecipientName: surpriseRecipientName ?? this.surpriseRecipientName,
      surpriseNote: surpriseNote ?? this.surpriseNote,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState();
  }

  void addToCart(ProductModel product) {
    // If cart has items from another shop, we can clear or update.
    // For hyperlocal, usually single shop per order
    if (state.items.isNotEmpty && state.items.first.product.shopId != product.shopId) {
      // replace cart with new shop product
      state = state.copyWith(items: [CartItem(product: product, quantity: 1)]);
      return;
    }

    final index = state.items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final updated = List<CartItem>.from(state.items);
      updated[index] = updated[index].copyWith(quantity: updated[index].quantity + 1);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(product: product, quantity: 1)]);
    }
  }

  void updateQuantity(String productId, int delta) {
    final index = state.items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final newQty = state.items[index].quantity + delta;
      final updated = List<CartItem>.from(state.items);
      if (newQty <= 0) {
        updated.removeAt(index);
      } else {
        updated[index] = updated[index].copyWith(quantity: newQty);
      }
      state = state.copyWith(items: updated);
    }
  }

  void setFulfillment(OrderFulfillment fulfillment) {
    state = state.copyWith(fulfillment: fulfillment);
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setSurpriseDelivery({
    required bool isSurprise,
    required String recipientName,
    required String note,
  }) {
    state = state.copyWith(
      isSurpriseDelivery: isSurprise,
      surpriseRecipientName: recipientName,
      surpriseNote: note,
    );
  }

  void clearCart() {
    state = const CartState();
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});

