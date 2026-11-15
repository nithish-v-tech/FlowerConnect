enum ShopType {
  flowerShop,
  bouquetShop,
  giftShop,
  hybrid,
}

class ShopModel {
  final String id;
  final String? userId;
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
    this.userId,
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
    String? userId,
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
      userId: userId ?? this.userId,
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

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    ShopType parsedType = ShopType.flowerShop;
    final typeStr = json['shop_type']?.toString().toUpperCase() ?? 'FLOWER_SHOP';
    if (typeStr == 'BOUQUET_SHOP') {
      parsedType = ShopType.bouquetShop;
    } else if (typeStr == 'GIFT_SHOP') {
      parsedType = ShopType.giftShop;
    } else if (typeStr == 'HYBRID') {
      parsedType = ShopType.hybrid;
    }

    Map<String, double> rates = {};
    if (json['daily_rates'] is Map) {
      (json['daily_rates'] as Map).forEach((k, v) {
        rates[k.toString()] = (v as num).toDouble();
      });
    }

    return ShopModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      name: json['name']?.toString() ?? '',
      type: parsedType,
      address: json['address']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 50,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 1.5,
      etaMinutes: (json['eta_minutes'] as num?)?.toInt() ?? 25,
      imageUrl: json['image_url']?.toString() ??
          'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=600&q=80',
      isVerified: json['is_verified'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      isOpen: json['is_open'] as bool? ?? true,
      dailyRates: rates,
      ownerName: json['owner_name']?.toString() ?? '',
      contactPhone: json['contact_phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'shop_type': type.name,
      'address': address,
      'rating': rating,
      'total_reviews': totalReviews,
      'image_url': imageUrl,
      'is_verified': isVerified,
      'is_featured': isFeatured,
      'is_open': isOpen,
      'daily_rates': dailyRates,
      'owner_name': ownerName,
      'contact_phone': contactPhone,
    };
  }
}

