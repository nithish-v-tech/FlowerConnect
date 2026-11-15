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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'title': title,
      'flower_type': flowerType,
      'quantity_description': quantityDescription,
      'occasion': occasion,
      'delivery_preference': deliveryPreference.name,
      'delivery_address': deliveryAddress,
      'target_budget': targetBudget,
      'need_by': needBy.toIso8601String(),
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'quotations_count': quotationsCount,
      'accepted_quotation_id': acceptedQuotationId,
    };
  }

  factory RFQModel.fromJson(Map<String, dynamic> json) {
    return RFQModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? 'Customer',
      title: json['title'] as String? ?? '',
      flowerType: json['flower_type'] as String? ?? '',
      quantityDescription: json['quantity_description'] as String? ?? '',
      occasion: json['occasion'] as String?,
      deliveryPreference: json['delivery_preference'] == 'selfPickup'
          ? DeliveryPreference.selfPickup
          : DeliveryPreference.homeDelivery,
      deliveryAddress: json['delivery_address'] as String? ?? '',
      targetBudget: (json['target_budget'] as num?)?.toDouble(),
      needBy: json['need_by'] != null
          ? DateTime.tryParse(json['need_by'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: RFQStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RFQStatus.broadcasting,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString()) ?? DateTime.now()
          : DateTime.now().add(const Duration(minutes: 45)),
      quotationsCount: (json['quotations_count'] as num?)?.toInt() ?? 0,
      acceptedQuotationId: json['accepted_quotation_id'] as String?,
    );
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

