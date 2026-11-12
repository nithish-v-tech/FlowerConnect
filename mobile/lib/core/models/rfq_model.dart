enum DeliveryPreference {
  homeDelivery,
  selfPickup,
}

enum RFQStatus {
  broadcasting,
  quotesReceived,
  accepted,
  expired,
  cancelled,
}

class RFQModel {
  final String id;
  final String customerId;
  final String customerName;
  final String title;
  final String flowerType;
  final String quantityDescription;
  final String? occasion;
  final DeliveryPreference deliveryPreference;
  final String deliveryAddress;
  final double? targetBudget;
  final DateTime needBy;
  final RFQStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int quotationsCount;
  final String? acceptedQuotationId;

  const RFQModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.title,
    required this.flowerType,
    required this.quantityDescription,
    this.occasion,
    required this.deliveryPreference,
    required this.deliveryAddress,
    this.targetBudget,
    required this.needBy,
    this.status = RFQStatus.broadcasting,
    required this.createdAt,
    required this.expiresAt,
    this.quotationsCount = 0,
    this.acceptedQuotationId,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  RFQModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? title,
    String? flowerType,
    String? quantityDescription,
    String? occasion,
    DeliveryPreference? deliveryPreference,
    String? deliveryAddress,
    double? targetBudget,
    DateTime? needBy,
    RFQStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? quotationsCount,
    String? acceptedQuotationId,
  }) {
    return RFQModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      title: title ?? this.title,
      flowerType: flowerType ?? this.flowerType,
      quantityDescription: quantityDescription ?? this.quantityDescription,
      occasion: occasion ?? this.occasion,
      deliveryPreference: deliveryPreference ?? this.deliveryPreference,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      targetBudget: targetBudget ?? this.targetBudget,
      needBy: needBy ?? this.needBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      quotationsCount: quotationsCount ?? this.quotationsCount,
      acceptedQuotationId: acceptedQuotationId ?? this.acceptedQuotationId,
    );
  }
}

