enum UserRole {
  customer,
  flowerMerchant,
  bouquetMerchant,
  giftMerchant,
  deliveryPartner,
  admin,
}

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.flowerMerchant:
        return 'Flower Merchant';
      case UserRole.bouquetMerchant:
        return 'Bouquet Merchant';
      case UserRole.giftMerchant:
        return 'Gift Merchant';
      case UserRole.deliveryPartner:
        return 'Delivery Partner';
      case UserRole.admin:
        return 'Super Admin';
    }
  }

  String get shortTag {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.flowerMerchant:
      case UserRole.bouquetMerchant:
      case UserRole.giftMerchant:
        return 'Merchant';
      case UserRole.deliveryPartner:
        return 'Delivery';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? shopId;
  final String? avatarUrl;
  final String address;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.shopId,
    this.avatarUrl,
    this.address = '14, Greenview Lane, Indiranagar, Bengaluru',
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? shopId,
    String? avatarUrl,
    String? address,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      shopId: shopId ?? this.shopId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      address: address ?? this.address,
    );
  }
}

