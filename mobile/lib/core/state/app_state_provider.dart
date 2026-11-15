import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';
import '../constants/demo_data.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';

class AppState {
  final UserModel currentUser;
  final List<ShopModel> shops;
  final List<ProductModel> products;
  final bool isDeliveryOnline;
  final double deliveryWalletBalance;
  final double platformCommissionRate; // e.g. 0.10 (10%)
  final double totalPlatformRevenue;

  const AppState({
    required this.currentUser,
    required this.shops,
    required this.products,
    this.isDeliveryOnline = true,
    this.deliveryWalletBalance = 680.0,
    this.platformCommissionRate = 0.10,
    this.totalPlatformRevenue = 8450.0,
  });

  AppState copyWith({
    UserModel? currentUser,
    List<ShopModel>? shops,
    List<ProductModel>? products,
    bool? isDeliveryOnline,
    double? deliveryWalletBalance,
    double? platformCommissionRate,
    double? totalPlatformRevenue,
  }) {
    return AppState(
      currentUser: currentUser ?? this.currentUser,
      shops: shops ?? this.shops,
      products: products ?? this.products,
      isDeliveryOnline: isDeliveryOnline ?? this.isDeliveryOnline,
      deliveryWalletBalance: deliveryWalletBalance ?? this.deliveryWalletBalance,
      platformCommissionRate: platformCommissionRate ?? this.platformCommissionRate,
      totalPlatformRevenue: totalPlatformRevenue ?? this.totalPlatformRevenue,
    );
  }
}

class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    return AppState(
      currentUser: const UserModel(
        id: 'cust_01',
        name: 'Pooja Hegde',
        email: 'pooja.h@example.com',
        phone: '+91 98765 43210',
        role: UserRole.customer,
      ),
      shops: List.from(DemoData.shops),
      products: List.from(DemoData.products),
    );
  }

  void switchRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        state = state.copyWith(
          currentUser: const UserModel(
            id: 'cust_01',
            name: 'Pooja Hegde',
            email: 'pooja.h@example.com',
            phone: '+91 98765 43210',
            role: UserRole.customer,
          ),
        );
        break;
      case UserRole.flowerMerchant:
        state = state.copyWith(
          currentUser: const UserModel(
            id: 'merchant_01',
            name: 'Muthu Kumar',
            email: 'srilakshmi.flowers@market.in',
            phone: '+91 98450 12345',
            role: UserRole.flowerMerchant,
            shopId: 'shop_001',
          ),
        );
        break;
      case UserRole.bouquetMerchant:
        state = state.copyWith(
          currentUser: const UserModel(
            id: 'merchant_02',
            name: 'Ananya Sharma',
            email: 'petals.studio@bangalore.in',
            phone: '+91 98451 98765',
            role: UserRole.bouquetMerchant,
            shopId: 'shop_002',
          ),
        );
        break;
      case UserRole.giftMerchant:
        state = state.copyWith(
          currentUser: const UserModel(
            id: 'merchant_03',
            name: 'Vikram Joshi',
            email: 'velvet.ribbon@gifts.in',
            phone: '+91 99160 55443',
            role: UserRole.giftMerchant,
            shopId: 'shop_003',
          ),
        );
        break;
      case UserRole.deliveryPartner:
        state = state.copyWith(
          currentUser: const UserModel(
            id: 'driver_01',
            name: 'Ramesh Gowda',
            email: 'ramesh.delivery@connect.in',
            phone: '+91 94480 33211',
            role: UserRole.deliveryPartner,
          ),
        );
        break;
      case UserRole.admin:
        state = state.copyWith(
          currentUser: const UserModel(
            id: 'admin_01',
            name: 'Antigravity Super Admin',
            email: 'admin@flowerconnect.app',
            phone: '+91 90000 00001',
            role: UserRole.admin,
          ),
        );
        break;
    }
  }

  void updateDailyFlowerRate(String shopId, String flowerName, double newRate) {
    state = state.copyWith(
      shops: state.shops.map((shop) {
        if (shop.id == shopId) {
          final updatedRates = Map<String, double>.from(shop.dailyRates);
          updatedRates[flowerName] = newRate;
          return shop.copyWith(dailyRates: updatedRates);
        }
        return shop;
      }).toList(),
    );
  }

  void toggleDeliveryDuty(bool isOnline) {
    state = state.copyWith(isDeliveryOnline: isOnline);
  }

  void addDeliveryEarning(double amount) {
    state = state.copyWith(
      deliveryWalletBalance: state.deliveryWalletBalance + amount,
    );
  }

  void updatePlatformCommissionRate(double newRate) {
    state = state.copyWith(platformCommissionRate: newRate);
  }

  void toggleProductStock(String productId) {
    state = state.copyWith(
      products: state.products.map((p) {
        if (p.id == productId) {
          return p.copyWith(inStock: !p.inStock);
        }
        return p;
      }).toList(),
    );
  }

  void setCurrentUser(UserModel user) {
    state = state.copyWith(currentUser: user);
  }

  void approveVendor(String shopId) {
    // Notify Cloud Firestore & FastAPI backend asynchronously
    FirestoreService.approveVendor(shopId);
    ApiService.approveVendor(shopId);

    // Update real-time UI state
    state = state.copyWith(
      shops: state.shops.map((shop) {
        if (shop.id == shopId) {
          return shop.copyWith(isVerified: true, isOpen: true);
        }
        return shop;
      }).toList(),
    );
  }

  Future<void> refreshFromBackend() async {
    // 1. Check Cloud Firestore (Free Spark Plan)
    final firestoreShops = await FirestoreService.getShops();
    final firestoreProducts = await FirestoreService.getProducts();

    if (firestoreShops != null && firestoreShops.isNotEmpty) {
      state = state.copyWith(shops: firestoreShops);
    }
    if (firestoreProducts != null && firestoreProducts.isNotEmpty) {
      state = state.copyWith(products: firestoreProducts);
    }

    // 2. Also check FastAPI backend
    final backendShops = await ApiService.fetchShops();
    final backendProducts = await ApiService.fetchProducts();

    if (backendShops != null && backendShops.isNotEmpty) {
      state = state.copyWith(shops: backendShops);
    }
    if (backendProducts != null && backendProducts.isNotEmpty) {
      state = state.copyWith(products: backendProducts);
    }
  }

  void registerNewShop(ShopModel newShop) {
    state = state.copyWith(shops: [...state.shops, newShop]);
  }

  void addProduct(ProductModel product) {
    state = state.copyWith(products: [product, ...state.products]);
  }
}

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(() {
  return AppStateNotifier();
});

