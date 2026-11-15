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

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'unit': unit,
      'image_url': imageUrl,
    };
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Flower Item',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unit: json['unit'] as String? ?? 'Bunch',
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'shop_id': shopId,
      'shop_name': shopName,
      'items': items.map((i) => i.toJson()).toList(),
      'items_total': itemsTotal,
      'delivery_fee': deliveryFee,
      'platform_commission': platformCommission,
      'grand_total': grandTotal,
      'fulfillment': fulfillment.name,
      'payment_method': paymentMethod.name,
      'payment_status': paymentStatus.name,
      'status': status.name,
      'delivery_address': deliveryAddress,
      'delivery_otp': deliveryOtp,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'driver_lat': driverLat,
      'driver_lng': driverLng,
      'is_surprise_delivery': isSurpriseDelivery,
      'surprise_recipient_name': surpriseRecipientName,
      'surprise_note': surpriseNote,
      'created_at': createdAt.toIso8601String(),
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'rating': rating,
      'review': review,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? 'Customer',
      customerPhone: json['customer_phone'] as String? ?? '',
      shopId: json['shop_id'] as String? ?? '',
      shopName: json['shop_name'] as String? ?? 'Flower Stall',
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      itemsTotal: (json['items_total'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 40.0,
      platformCommission: (json['platform_commission'] as num?)?.toDouble() ?? 25.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      fulfillment: OrderFulfillment.values.firstWhere(
        (e) => e.name == json['fulfillment'],
        orElse: () => OrderFulfillment.homeDelivery,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['payment_method'],
        orElse: () => PaymentMethod.upi,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.placed,
      ),
      deliveryAddress: json['delivery_address'] as String? ?? '',
      deliveryOtp: json['delivery_otp'] as String?,
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      driverLat: (json['driver_lat'] as num?)?.toDouble(),
      driverLng: (json['driver_lng'] as num?)?.toDouble(),
      isSurpriseDelivery: json['is_surprise_delivery'] as bool? ?? false,
      surpriseRecipientName: json['surprise_recipient_name'] as String?,
      surpriseNote: json['surprise_note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.tryParse(json['estimated_delivery_time'].toString())
          : null,
      rating: (json['rating'] as num?)?.toInt(),
      review: json['review'] as String?,
    );
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
