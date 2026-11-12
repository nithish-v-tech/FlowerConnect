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

  QuotationModel copyWith({
    String? id,
    String? rfqId,
    String? merchantId,
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

