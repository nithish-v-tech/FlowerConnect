import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/state/rfq_provider.dart';
import '../../core/state/order_provider.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/state/auth_state_provider.dart';
import 'customer_home_screen.dart';
import '../bouquet_builder/custom_bouquet_builder_screen.dart';
import '../quotation/quotation_comparison_screen.dart';
import '../quotation/create_rfq_screen.dart';
import 'order_history_screen.dart';
import '../portal/portal_selection_screen.dart';

class CustomerMainNav extends ConsumerStatefulWidget {
  const CustomerMainNav({super.key});

  @override
  ConsumerState<CustomerMainNav> createState() => _CustomerMainNavState();
}

class _CustomerMainNavState extends ConsumerState<CustomerMainNav> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(appStateProvider).currentUser;
      ref.read(rfqProvider.notifier).refreshFromFirestore(customerId: user.id);
      ref.read(orderProvider.notifier).refreshFromFirestore(customerId: user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rfqState = ref.watch(rfqProvider);
    final activeRfqId = rfqState.activeRfqId ?? (rfqState.requests.isNotEmpty ? rfqState.requests.first.id : null);

    final List<Widget> pages = [
      const CustomerHomeScreen(),
      const CustomBouquetBuilderScreen(),
      activeRfqId != null
          ? QuotationComparisonScreen(rfqId: activeRfqId)
          : const CreateRFQScreen(),
      const OrderHistoryScreen(),
      const _CustomerProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.divider)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.palette_outlined),
              activeIcon: Icon(Icons.palette),
              label: 'Bouquet Studio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.request_quote_outlined),
              activeIcon: Icon(Icons.request_quote),
              label: 'RFQ Quotes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerProfileTab extends ConsumerWidget {
  const _CustomerProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person, size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text(user.phone, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Portal Switcher Tile
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const PortalSelectionScreen()),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    color: AppColors.primaryLight.withOpacity(0.4),
                  ),
                  child: const ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.apps, color: Colors.white),
                    ),
                    title: Text('Switch Workspace Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Return to Customer / Vendor / Admin selection', style: TextStyle(fontSize: 11)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Addresses Tile
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    title: const Text('Saved Addresses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(user.address, style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.edit, size: 16),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.favorite_border, color: AppColors.primary),
                    title: const Text('Favourite Florists & Stalls', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Sri Lakshmi, Petals & Blooms', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.support_agent, color: AppColors.primary),
                    title: const Text('Help & Customer Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Call 1800-420-FLOWERS', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                    subtitle: const Text('Switch mobile account', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red),
                    onTap: () {
                      ref.read(authStateProvider.notifier).logout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
