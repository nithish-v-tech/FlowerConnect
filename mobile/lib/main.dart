import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/models/user_model.dart';
import 'core/state/app_state_provider.dart';
import 'core/state/auth_state_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/vendor_approval_pending_screen.dart';
import 'features/customer/customer_main_nav.dart';
import 'features/merchant/merchant_dashboard_screen.dart';
import 'features/delivery/delivery_dashboard_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[Firebase] Initialization notice: $e');
  }
  runApp(const ProviderScope(child: FlowerConnectApp()));
}

class FlowerConnectApp extends ConsumerStatefulWidget {
  const FlowerConnectApp({super.key});

  @override
  ConsumerState<FlowerConnectApp> createState() => _FlowerConnectAppState();
}

class _FlowerConnectAppState extends ConsumerState<FlowerConnectApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appStateProvider.notifier).refreshFromBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final appState = ref.watch(appStateProvider);

    return MaterialApp(
      title: 'FlowerConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _resolvePortalScreen(authState, appState),
    );
  }

  Widget _resolvePortalScreen(AuthState authState, AppState appState) {
    // 1. If not authenticated via mobile OTP, present Login Screen
    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    final currentUser = appState.currentUser;
    final role = currentUser.role;

    // 2. Identify role and navigate to appropriate dashboard
    switch (role) {
      case UserRole.customer:
        return const CustomerMainNav();

      case UserRole.flowerMerchant:
      case UserRole.bouquetMerchant:
      case UserRole.giftMerchant:
        // Check shop verification status from shared state
        final shop = appState.shops.firstWhere(
          (s) => s.id == currentUser.shopId,
          orElse: () => appState.shops.first,
        );

        // If vendor is approved by admin, load Vendor Dashboard; otherwise show Pending Screen
        if (shop.isVerified) {
          return const MerchantDashboardScreen();
        } else {
          return const VendorApprovalPendingScreen();
        }

      case UserRole.deliveryPartner:
        return const DeliveryDashboardScreen();

      case UserRole.admin:
        return const AdminDashboardScreen();
    }
  }
}
