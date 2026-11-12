import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/models/user_model.dart';
import 'core/state/app_state_provider.dart';
import 'features/customer/customer_main_nav.dart';
import 'features/merchant/merchant_dashboard_screen.dart';
import 'features/delivery/delivery_dashboard_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: FlowerConnectApp()));
}

class FlowerConnectApp extends ConsumerWidget {
  const FlowerConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final userRole = appState.currentUser.role;

    return MaterialApp(
      title: 'FlowerConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _buildHomeForRole(userRole),
    );
  }

  Widget _buildHomeForRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return const CustomerMainNav();
      case UserRole.flowerMerchant:
      case UserRole.bouquetMerchant:
      case UserRole.giftMerchant:
        return const MerchantDashboardScreen();
      case UserRole.deliveryPartner:
        return const DeliveryDashboardScreen();
      case UserRole.admin:
        return const AdminDashboardScreen();
    }
  }
}
