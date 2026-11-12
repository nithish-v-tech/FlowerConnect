enum OrderStatus {
  placed,
  confirmed,
  preparing,
  outForDelivery,
  readyForPickup,
  delivered,
  cancelled,
}

enum OrderFulfillment {
  homeDelivery,
  selfPickup,
}

enum PaymentMethod {
  upi,
  cashOnDelivery,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
}

class OrderItemModel {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String unit;
  final String imageUrl;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.unit,
    required this.imageUrl,
  });

  double get totalPrice => unitPrice * quantity;
}

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String shopId;
  final String shopName;
  final List<OrderItemModel> items;
  final double itemsTotal;
  final double deliveryFee;
  final double platformCommission;
  final double grandTotal;
  final OrderFulfillment fulfillment;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final OrderStatus status;
  final String deliveryAddress;
  final String? deliveryOtp; // 4-digit code shown to customer, verified by partner
  final String? driverName;
  final String? driverPhone;
  final double? driverLat;
  final double? driverLng;
  final bool isSurpriseDelivery;
  final String? surpriseRecipientName;
  final String? surpriseNote;
  final DateTime createdAt;
  final DateTime? estimatedDeliveryTime;
  final int? rating;
  final String? review;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.itemsTotal,
    this.deliveryFee = 40.0,
    this.platformCommission = 25.0,
    required this.grandTotal,
    required this.fulfillment,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.pending,
    this.status = OrderStatus.placed,
    required this.deliveryAddress,
    this.deliveryOtp = '4821',
    this.driverName,
    this.driverPhone,
    this.driverLat,
    this.driverLng,
    this.isSurpriseDelivery = false,
    this.surpriseRecipientName,
    this.surpriseNote,
    required this.createdAt,
    this.estimatedDeliveryTime,
    this.rating,
    this.review,
  });

  String get statusDisplay {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Merchant Accepted';
      case OrderStatus.preparing:
        return 'Arranging Flowers';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? shopId,
    String? shopName,
    List<OrderItemModel>? items,
    double? itemsTotal,
    double? deliveryFee,
    double? platformCommission,
    double? grandTotal,
    OrderFulfillment? fulfillment,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    OrderStatus? status,
    String? deliveryAddress,
    String? deliveryOtp,
    String? driverName,
    String? driverPhone,
    double? driverLat,
    double? driverLng,
    bool? isSurpriseDelivery,
    String? surpriseRecipientName,
    String? surpriseNote,
    DateTime? createdAt,
    DateTime? estimatedDeliveryTime,
    int? rating,
    String? review,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      items: items ?? this.items,
      itemsTotal: itemsTotal ?? this.itemsTotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      platformCommission: platformCommission ?? this.platformCommission,
      grandTotal: grandTotal ?? this.grandTotal,
      fulfillment: fulfillment ?? this.fulfillment,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverLat: driverLat ?? this.driverLat,
      driverLng: driverLng ?? this.driverLng,
      isSurpriseDelivery: isSurpriseDelivery ?? this.isSurpriseDelivery,
      surpriseRecipientName: surpriseRecipientName ?? this.surpriseRecipientName,
      surpriseNote: surpriseNote ?? this.surpriseNote,
      createdAt: createdAt ?? this.createdAt,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }
}
