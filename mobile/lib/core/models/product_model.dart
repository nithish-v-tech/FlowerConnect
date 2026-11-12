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
}

