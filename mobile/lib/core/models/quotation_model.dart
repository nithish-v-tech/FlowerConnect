enum QuotationStatus {
  pending,
  accepted,
  rejected,
  expired,
}

class QuotationModel {
  final String id;
  final String rfqId;
  final String merchantId;
  final String? shopId;
  final String shopName;
  final String merchantPhone;
  final double merchantRating;
  final double distanceKm;
  final double quotedPrice;
  final double deliveryFee;
  final int prepTimeMinutes;
  final String notes;
  final String freshnessGuarantee;
  final QuotationStatus status;
  final DateTime submittedAt;
  final DateTime expiresAt;

  const QuotationModel({
    required this.id,
    required this.rfqId,
    required this.merchantId,
    this.shopId,
    required this.shopName,
    required this.merchantPhone,
    required this.merchantRating,
    required this.distanceKm,
    required this.quotedPrice,
    this.deliveryFee = 40.0,
    required this.prepTimeMinutes,
    required this.notes,
    this.freshnessGuarantee = 'Guaranteed 100% farm-fresh morning cuts',
    this.status = QuotationStatus.pending,
    required this.submittedAt,
    required this.expiresAt,
  });

  double get grandTotal => quotedPrice + deliveryFee;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rfq_id': rfqId,
      'merchant_id': merchantId,
      'shop_id': shopId ?? merchantId,
      'shop_name': shopName,
      'merchant_phone': merchantPhone,
      'merchant_rating': merchantRating,
      'distance_km': distanceKm,
      'quoted_price': quotedPrice,
      'delivery_fee': deliveryFee,
      'prep_time_minutes': prepTimeMinutes,
      'notes': notes,
      'freshness_guarantee': freshnessGuarantee,
      'status': status.name,
      'submitted_at': submittedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    return QuotationModel(
      id: json['id'] as String,
      rfqId: json['rfq_id'] as String? ?? '',
      merchantId: json['merchant_id'] as String? ?? '',
      shopId: json['shop_id'] as String?,
      shopName: json['shop_name'] as String? ?? 'Flower Shop',
      merchantPhone: json['merchant_phone'] as String? ?? '',
      merchantRating: (json['merchant_rating'] as num?)?.toDouble() ?? 4.8,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 1.5,
      quotedPrice: (json['quoted_price'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 40.0,
      prepTimeMinutes: (json['prep_time_minutes'] as num?)?.toInt() ?? 25,
      notes: json['notes'] as String? ?? '',
      freshnessGuarantee: json['freshness_guarantee'] as String? ??
          'Guaranteed 100% farm-fresh morning cuts',
      status: QuotationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => QuotationStatus.pending,
      ),
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString()) ?? DateTime.now()
          : DateTime.now().add(const Duration(minutes: 45)),
    );
  }

  QuotationModel copyWith({
    String? id,
    String? rfqId,
    String? merchantId,
    String? shopId,
    String? shopName,
    String? merchantPhone,
    double? merchantRating,
    double? distanceKm,
    double? quotedPrice,
    double? deliveryFee,
    int? prepTimeMinutes,
    String? notes,
    String? freshnessGuarantee,
    QuotationStatus? status,
    DateTime? submittedAt,
    DateTime? expiresAt,
  }) {
    return QuotationModel(
      id: id ?? this.id,
      rfqId: rfqId ?? this.rfqId,
      merchantId: merchantId ?? this.merchantId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      merchantPhone: merchantPhone ?? this.merchantPhone,
      merchantRating: merchantRating ?? this.merchantRating,
      distanceKm: distanceKm ?? this.distanceKm,
      quotedPrice: quotedPrice ?? this.quotedPrice,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      notes: notes ?? this.notes,
      freshnessGuarantee: freshnessGuarantee ?? this.freshnessGuarantee,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

