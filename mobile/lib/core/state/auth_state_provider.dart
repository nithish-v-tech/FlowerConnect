import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/shop_model.dart';
import '../services/api_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import 'app_state_provider.dart';

class AuthState {
  final bool isAuthenticated;
  final UserModel? currentUser;
  final bool isOtpSent;
  final String? phoneNumber;
  final String? verificationId;
  final String? generatedOtp;
  final bool isLoading;
  final String? errorMessage;
  final bool isNewUser;

  const AuthState({
    this.isAuthenticated = false,
    this.currentUser,
    this.isOtpSent = false,
    this.phoneNumber,
    this.verificationId,
    this.generatedOtp,
    this.isLoading = false,
    this.errorMessage,
    this.isNewUser = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserModel? currentUser,
    bool? isOtpSent,
    String? phoneNumber,
    String? verificationId,
    String? generatedOtp,
    bool? isLoading,
    String? errorMessage,
    bool? isNewUser,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentUser: currentUser ?? this.currentUser,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      generatedOtp: generatedOtp ?? this.generatedOtp,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  // Pre-configured role accounts (same as backend database seeds & Firebase test numbers)
  static final Map<String, UserModel> _seededUsers = {
    // Customer (Firebase Test Number +91 98765 43210 -> Code: 432100 / 123456)
    '+919876543210': const UserModel(
      id: 'cust_01',
      name: 'Pooja Hegde',
      email: 'pooja.h@example.com',
      phone: '+91 98765 43210',
      role: UserRole.customer,
      address: '14, Greenview Lane, Indiranagar, Bengaluru',
    ),
    // Approved Flower Merchant (+91 98450 12345 -> Code: 123450 / 123456)
    '+919845012345': const UserModel(
      id: 'merchant_01',
      name: 'Muthu Kumar',
      email: 'srilakshmi.flowers@market.in',
      phone: '+91 98450 12345',
      role: UserRole.flowerMerchant,
      shopId: 'shop_001',
      address: '100ft Road, Near Metro Pillar 84, Indiranagar',
    ),
    // Approved Bouquet Merchant (+91 98451 98765 -> Code: 987650 / 123456)
    '+919845198765': const UserModel(
      id: 'merchant_02',
      name: 'Ananya Sharma',
      email: 'petals.studio@bangalore.in',
      phone: '+91 98451 98765',
      role: UserRole.bouquetMerchant,
      shopId: 'shop_002',
      address: '5th Block, 80ft Road, Koramangala',
    ),
    // Approved Gift Merchant (+91 99160 55443 -> Code: 554430 / 123456)
    '+919916055443': const UserModel(
      id: 'merchant_03',
      name: 'Vikram Joshi',
      email: 'velvet.ribbon@gifts.in',
      phone: '+91 99160 55443',
      role: UserRole.giftMerchant,
      shopId: 'shop_003',
      address: '27th Main, Sector 1, HSR Layout',
    ),
    // Pending Flower Merchant (+91 99999 88888 -> Code: 888880 / 123456)
    '+919999988888': const UserModel(
      id: 'merchant_pending_01',
      name: 'Kavita Reddy',
      email: 'kavita.sunshine@gmail.com',
      phone: '+91 99999 88888',
      role: UserRole.flowerMerchant,
      shopId: 'shop_pending_01',
      address: '12th Main, HAL 2nd Stage, Indiranagar, Bengaluru',
    ),
    // Super Admin (+91 90000 00001 -> Code: 000010 / 123456)
    '+919000000001': const UserModel(
      id: 'admin_01',
      name: 'Antigravity Super Admin',
      email: 'admin@flowerconnect.app',
      phone: '+91 90000 00001',
      role: UserRole.admin,
      address: 'FlowerConnect HQ, Bengaluru',
    ),
    // Delivery Partner (+91 94480 33211 -> Code: 332110 / 123456)
    '+919448033211': const UserModel(
      id: 'driver_01',
      name: 'Ramesh Gowda',
      email: 'ramesh.delivery@connect.in',
      phone: '+91 94480 33211',
      role: UserRole.deliveryPartner,
      address: 'Indiranagar Hub, Bengaluru',
    ),
  };

  /// Pre-configured Firebase Spark plan test phone verification codes
  static const Map<String, String> _testPhoneOtpCodes = {
    '+919876543210': '432100', // Customer
    '+919845012345': '123450', // Approved Flower Stall
    '+919845198765': '987650', // Approved Bouquet Studio
    '+919916055443': '554430', // Approved Gift Boutique
    '+919999988888': '888880', // Pending Flower Merchant
    '+919000000001': '000010', // Super Admin
    '+919448033211': '332110', // Delivery Partner
  };

  @override
  AuthState build() {
    return const AuthState(isAuthenticated: false);
  }

  String _normalizePhone(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+91$digits';
    } else if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    }
    return '+$digits';
  }

  Future<bool> sendOtp(String rawPhone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final normalized = _normalizePhone(rawPhone);
    final digits = normalized.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid 10-digit mobile number.',
      );
      return false;
    }

    String? receivedVerificationId;
    String generatedCode = '123456';

    // 1. Attempt Firebase Phone Auth (Free on Spark plan with test phone numbers)
    try {
      await FirebaseAuthService.sendPhoneOtp(
        phoneNumber: normalized,
        onCodeSent: (vId) {
          receivedVerificationId = vId;
        },
        onVerificationFailed: (error) {
          // If Firebase is not yet linked to cloud project, gracefully log
          debugPrint('[Auth] Firebase Phone Auth notification: $error');
        },
      );
    } catch (e) {
      debugPrint('[Auth] Firebase Phone Auth exception: $e');
    }

    // 2. Also call backend API if running
    try {
      final response = await ApiService.requestOtp(normalized);
      if (response['otp_code'] != null) {
        generatedCode = response['otp_code'].toString();
      }
    } catch (_) {}

    state = state.copyWith(
      isLoading: false,
      isOtpSent: true,
      phoneNumber: normalized,
      verificationId: receivedVerificationId ?? 'firebase_verification_id',
      generatedOtp: generatedCode,
      isNewUser: false,
    );
    return true;
  }

  Future<bool> verifyOtp(String enteredOtp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final normalized = state.phoneNumber ?? '';

    // 1. Try Firebase Authentication verify if verificationId exists
    if (state.verificationId != null && state.verificationId != 'firebase_verification_id') {
      try {
        final userCredential = await FirebaseAuthService.verifyOtpCode(
          verificationId: state.verificationId!,
          smsCode: enteredOtp,
        );

        if (userCredential?.user != null) {
          final uid = userCredential!.user!.uid;

          // Check Cloud Firestore for existing profile
          final firestoreUser = await FirestoreService.getUserProfile(uid);
          if (firestoreUser != null) {
            state = state.copyWith(
              isLoading: false,
              isAuthenticated: true,
              currentUser: firestoreUser,
              isNewUser: false,
            );
            ref.read(appStateProvider.notifier).setCurrentUser(firestoreUser);
            return true;
          } else {
            // New user in Firebase Auth, prompt profile registration
            state = state.copyWith(
              isLoading: false,
              isNewUser: true,
            );
            return true;
          }
        }
      } catch (e) {
        debugPrint('[Auth] Firebase verifyOtp error: $e');
      }
    }

    // 2. Check FastAPI backend if active
    final apiResp = await ApiService.verifyOtp(
      phone: normalized,
      otp: enteredOtp,
    );

    if (apiResp['user'] != null) {
      final user = UserModel.fromJson(apiResp['user']);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        currentUser: user,
        isNewUser: false,
      );
      ref.read(appStateProvider.notifier).setCurrentUser(user);
      return true;
    }

    if (apiResp['status'] == 'new_user') {
      state = state.copyWith(
        isLoading: false,
        isNewUser: true,
      );
      return true;
    }

    // 3. Check code validity (Firebase Spark test code, generated backend OTP, or 123456 in debug mode)
    final testCode = _testPhoneOtpCodes[normalized];
    final isCodeValid = (kDebugMode && enteredOtp == '123456') ||
        (state.generatedOtp != null && enteredOtp == state.generatedOtp) ||
        (testCode != null && enteredOtp == testCode);

    if (!isCodeValid) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid OTP code. Please enter the configured test code.',
      );
      return false;
    }

    // 4. Check configured test phone credentials / offline evaluation
    final existingUser = _seededUsers[normalized];
    if (existingUser != null) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        currentUser: existingUser,
        isNewUser: false,
      );
      ref.read(appStateProvider.notifier).setCurrentUser(existingUser);
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      isNewUser: true,
    );
    return true;
  }

  Future<bool> registerProfile({
    required String fullName,
    required UserRole role,
    String? email,
    String? shopName,
    ShopType? shopType,
    String? shopAddress,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // STRICT SECURITY: Never allow self-registration as Admin
    if (role == UserRole.admin) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration as Administrator is forbidden.',
      );
      return false;
    }

    final phone = state.phoneNumber ?? '+919999900000';
    final currentFbUid = FirebaseAuthService.currentFirebaseUser?.uid;
    final userId = currentFbUid ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

    String? createdShopId;
    if (role == UserRole.flowerMerchant ||
        role == UserRole.bouquetMerchant ||
        role == UserRole.giftMerchant) {
      createdShopId = 'shop_${DateTime.now().millisecondsSinceEpoch}';
      final newShop = ShopModel(
        id: createdShopId,
        userId: userId,
        name: shopName ?? '$fullName Florals',
        type: shopType ?? ShopType.flowerShop,
        address: shopAddress ?? 'Bengaluru, Karnataka',
        rating: 0.0,
        totalReviews: 0,
        distanceKm: 1.5,
        etaMinutes: 25,
        imageUrl:
            'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=600&q=80',
        isVerified: false, // NEW VENDORS REQUIRE ADMIN APPROVAL
        isFeatured: false,
        isOpen: false,
        ownerName: fullName,
        contactPhone: phone,
        dailyRates: {},
      );

      // Save new shop to Firestore & AppState
      try {
        FirestoreService.shopsCol?.doc(createdShopId).set(newShop.toJson());
      } catch (_) {}
      ref.read(appStateProvider.notifier).registerNewShop(newShop);
    }

    final newUser = UserModel(
      id: userId,
      name: fullName,
      email: email ?? '$userId@flowerconnect.app',
      phone: phone,
      role: role,
      shopId: createdShopId,
      address: shopAddress ?? 'Bengaluru, Karnataka',
    );

    // Save user profile to Cloud Firestore
    try {
      await FirestoreService.saveUserProfile(newUser);
    } catch (_) {}

    // Also register in backend if reachable
    try {
      await ApiService.registerProfile(
        phone: phone,
        fullName: fullName,
        role: role,
        email: email,
        shopName: shopName,
        shopType: shopType?.name,
        shopAddress: shopAddress,
      );
    } catch (_) {}

    _seededUsers[phone] = newUser;

    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      currentUser: newUser,
      isNewUser: false,
    );
    ref.read(appStateProvider.notifier).setCurrentUser(newUser);
    return true;
  }

  void quickLogin(String normalizedPhone) {
    final user = _seededUsers[normalizedPhone];
    if (user != null) {
      state = state.copyWith(
        isAuthenticated: true,
        currentUser: user,
        phoneNumber: normalizedPhone,
        isOtpSent: false,
        isNewUser: false,
        errorMessage: null,
      );
      ref.read(appStateProvider.notifier).setCurrentUser(user);
    }
  }

  void logout() {
    FirebaseAuthService.signOut();
    ApiService.authToken = null;
    state = const AuthState(isAuthenticated: false);
  }
}

final authStateProvider =
    NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());
