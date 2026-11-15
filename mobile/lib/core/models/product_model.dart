enum ProductCategory {
  freshFlowers,
  readyBouquets,
  roses,
  lilies,
  exotics,
  chocolates,
  plushToys,
  greetingCards,
  giftHampers,
  customBouquet,
}

extension ProductCategoryExtension on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.freshFlowers:
        return 'Fresh Flowers';
      case ProductCategory.readyBouquets:
        return 'Bouquets';
      case ProductCategory.roses:
        return 'Roses';
      case ProductCategory.lilies:
        return 'Lilies';
      case ProductCategory.exotics:
        return 'Exotic Flora';
      case ProductCategory.chocolates:
        return 'Chocolates';
      case ProductCategory.plushToys:
        return 'Teddy & Plush';
      case ProductCategory.greetingCards:
        return 'Cards';
      case ProductCategory.giftHampers:
        return 'Gift Hampers';
      case ProductCategory.customBouquet:
        return 'Custom Builder';
    }
  }

  String get emoji {
    switch (this) {
      case ProductCategory.freshFlowers:
        return '🌸';
      case ProductCategory.readyBouquets:
        return '💐';
      case ProductCategory.roses:
        return '🌹';
      case ProductCategory.lilies:
        return '🪷';
      case ProductCategory.exotics:
        return '🌺';
      case ProductCategory.chocolates:
        return '🍫';
      case ProductCategory.plushToys:
        return '🧸';
      case ProductCategory.greetingCards:
        return '💌';
      case ProductCategory.giftHampers:
        return '🎁';
      case ProductCategory.customBouquet:
        return '✨';
    }
  }
}

class ProductModel {
  final String id;
  final String shopId;
  final String shopName;
  final String name;
  final String description;
  final ProductCategory category;
  final double price;
  final double? originalPrice;
  final String unit; // 'bunch', 'kg', 'piece', 'box'
  final String imageUrl;
  final double rating;
  final int reviewsCount;
  final bool inStock;
  final bool isBestseller;
  final List<String> tags;

  const ProductModel({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.unit,
    required this.imageUrl,
    this.rating = 4.8,
    this.reviewsCount = 42,
    this.inStock = true,
    this.isBestseller = false,
    this.tags = const [],
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  int get discountPercentage => hasDiscount
      ? (((originalPrice! - price) / originalPrice!) * 100).round()
      : 0;

  ProductModel copyWith({
    String? id,
    String? shopId,
    String? shopName,
    String? name,
    String? description,
    ProductCategory? category,
    double? price,
    double? originalPrice,
    String? unit,
    String? imageUrl,
    double? rating,
    int? reviewsCount,
    bool? inStock,
    bool? isBestseller,
    List<String>? tags,
  }) {
    return ProductModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      inStock: inStock ?? this.inStock,
      isBestseller: isBestseller ?? this.isBestseller,
      tags: tags ?? this.tags,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json, {String? defaultShopName}) {
    ProductCategory parsedCategory = ProductCategory.freshFlowers;
    final catStr = json['category']?.toString().toUpperCase() ?? 'FRESH_FLOWERS';
    if (catStr.contains('READY_BOUQUETS')) {
      parsedCategory = ProductCategory.readyBouquets;
    } else if (catStr.contains('ROSES')) {
      parsedCategory = ProductCategory.roses;
    } else if (catStr.contains('LILIES')) {
      parsedCategory = ProductCategory.lilies;
    } else if (catStr.contains('EXOTICS')) {
      parsedCategory = ProductCategory.exotics;
    } else if (catStr.contains('CHOCOLATES')) {
      parsedCategory = ProductCategory.chocolates;
    } else if (catStr.contains('PLUSH_TOYS')) {
      parsedCategory = ProductCategory.plushToys;
    } else if (catStr.contains('GREETING_CARDS')) {
      parsedCategory = ProductCategory.greetingCards;
    } else if (catStr.contains('GIFT_HAMPERS')) {
      parsedCategory = ProductCategory.giftHampers;
    }

    return ProductModel(
      id: json['id']?.toString() ?? '',
      shopId: json['shop_id']?.toString() ?? '',
      shopName: json['shop_name']?.toString() ?? defaultShopName ?? 'Florist Stall',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: parsedCategory,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      unit: json['unit']?.toString() ?? 'piece',
      imageUrl: json['image_url']?.toString() ??
          'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=600&q=80',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 20,
      inStock: json['in_stock'] as bool? ?? true,
      isBestseller: json['is_bestseller'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'description': description,
      'category': category.name,
      'price': price,
      'original_price': originalPrice,
      'unit': unit,
      'image_url': imageUrl,
      'in_stock': inStock,
      'is_bestseller': isBestseller,
    };
  }
}

