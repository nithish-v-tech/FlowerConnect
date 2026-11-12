enum ShopType {
  flowerShop,
  bouquetShop,
  giftShop,
  hybrid,
}

class ShopModel {
  final String id;
  final String name;
  final ShopType type;
  final String address;
  final double rating;
  final int totalReviews;
  final double distanceKm;
  final int etaMinutes;
  final String imageUrl;
  final bool isVerified;
  final bool isFeatured;
  final bool isOpen;
  final Map<String, double> dailyRates; // e.g. {'Jasmine (Mogra)': 450.0, 'Dutch Red Rose': 320.0}
  final String ownerName;
  final String contactPhone;

  const ShopModel({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.rating,
    required this.totalReviews,
    required this.distanceKm,
    required this.etaMinutes,
    required this.imageUrl,
    this.isVerified = true,
    this.isFeatured = false,
    this.isOpen = true,
    required this.dailyRates,
    required this.ownerName,
    required this.contactPhone,
  });

  String get typeLabel {
    switch (type) {
      case ShopType.flowerShop:
        return 'Local Flower Stall';
      case ShopType.bouquetShop:
        return 'Artisan Bouquet Studio';
      case ShopType.giftShop:
        return 'Gift & Hamper Boutique';
      case ShopType.hybrid:
        return 'Flowers & Gifts';
    }
  }

  ShopModel copyWith({
    String? id,
    String? name,
    ShopType? type,
    String? address,
    double? rating,
    int? totalReviews,
    double? distanceKm,
    int? etaMinutes,
    String? imageUrl,
    bool? isVerified,
    bool? isFeatured,
    bool? isOpen,
    Map<String, double>? dailyRates,
    String? ownerName,
    String? contactPhone,
  }) {
    return ShopModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      imageUrl: imageUrl ?? this.imageUrl,
      isVerified: isVerified ?? this.isVerified,
      isFeatured: isFeatured ?? this.isFeatured,
      isOpen: isOpen ?? this.isOpen,
      dailyRates: dailyRates ?? this.dailyRates,
      ownerName: ownerName ?? this.ownerName,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }
}

