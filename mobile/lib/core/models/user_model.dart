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
  final bool isVendorApproved;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.shopId,
    this.avatarUrl,
    this.address = '14, Greenview Lane, Indiranagar, Bengaluru',
    this.isVendorApproved = false,
  });

  bool get isAdmin => role == UserRole.admin;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? shopId,
    String? avatarUrl,
    String? address,
    bool? isVendorApproved,
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
      isVendorApproved: isVendorApproved ?? this.isVendorApproved,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.customer;
    final roleStr = json['role']?.toString().toUpperCase() ?? 'CUSTOMER';
    if (roleStr.contains('FLOWER_MERCHANT') || roleStr.contains('FLOWERMERCHANT')) {
      parsedRole = UserRole.flowerMerchant;
    } else if (roleStr.contains('BOUQUET_MERCHANT') || roleStr.contains('BOUQUETMERCHANT')) {
      parsedRole = UserRole.bouquetMerchant;
    } else if (roleStr.contains('GIFT_MERCHANT') || roleStr.contains('GIFTMERCHANT')) {
      parsedRole = UserRole.giftMerchant;
    } else if (roleStr.contains('DELIVERY_PARTNER') || roleStr.contains('DELIVERYPARTNER')) {
      parsedRole = UserRole.deliveryPartner;
    } else if (roleStr.contains('ADMIN')) {
      parsedRole = UserRole.admin;
    }

    final isApproved = json['is_vendor_approved'] == true ||
        json['isVendorApproved'] == true;

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['full_name']?.toString() ?? json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: parsedRole,
      shopId: json['shop_id']?.toString(),
      address: json['address']?.toString() ?? 'Bengaluru, Karnataka',
      isVendorApproved: isApproved,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'shop_id': shopId,
      'address': address,
      'is_vendor_approved': isVendorApproved,
    };
  }
}

