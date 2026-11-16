import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../core/models/shop_model.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/state/auth_state_provider.dart';
import '../../core/services/firestore_service.dart';
import '../customer/customer_main_nav.dart';
import '../merchant/merchant_dashboard_screen.dart';
import '../merchant/vendor_shop_registration_screen.dart';
import '../auth/vendor_approval_pending_screen.dart';
import '../auth/login_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class PortalSelectionScreen extends ConsumerStatefulWidget {
  const PortalSelectionScreen({super.key});

  @override
  ConsumerState<PortalSelectionScreen> createState() =>
      _PortalSelectionScreenState();
}

class _PortalSelectionScreenState extends ConsumerState<PortalSelectionScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(appStateProvider.notifier).refreshFromBackend();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  ShopModel? _findUserShop(UserModel user, List<ShopModel> shops) {
    if (user.shopId != null) {
      for (final s in shops) {
        if (s.id == user.shopId) return s;
      }
    }
    for (final s in shops) {
      if (s.userId == user.id) return s;
    }
    return null;
  }

  Future<void> _handleVendorPortalTap(UserModel user, List<ShopModel> shops) async {
    setState(() => _isLoading = true);

    // Refresh shop directly from Firestore to ensure latest admin verification state
    ShopModel? userShop = _findUserShop(user, shops);
    if (userShop == null) {
      userShop = await FirestoreService.getShopByUserId(user.id);
      if (userShop != null) {
        ref.read(appStateProvider.notifier).registerNewShop(userShop);
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (userShop == null) {
      // Vendor has not registered a shop yet -> open shop registration
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const VendorShopRegistrationScreen(),
        ),
      );
    } else if (!userShop.isVerified) {
      // Shop registered but waiting for Admin approval
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VendorApprovalPendingScreen(shop: userShop),
        ),
      );
    } else {
      // Shop is approved by Admin -> enter merchant dashboard
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MerchantDashboardScreen(),
        ),
      );
    }
  }

  Future<void> _handleAdminPortalTap(UserModel user) async {
    setState(() => _isLoading = true);

    // Verify role directly from Firestore document for absolute security
    final profile = await FirestoreService.getUserProfile(user.id);
    final isSecureAdmin = profile?.role == UserRole.admin || user.role == UserRole.admin;

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isSecureAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboardScreen(),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.redAccent, size: 26),
              SizedBox(width: 10),
              Text('Access Restricted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account: ${user.phone.isNotEmpty ? user.phone : user.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 10),
              const Text(
                'This account is not provisioned as a Platform Administrator.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  'SECURITY NOTICE: Self-assignment of administrative privileges is blocked by Firestore Security Rules. Admin roles must be assigned directly in the database.',
                  style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final appState = ref.watch(appStateProvider);
    final user = authState.currentUser ?? appState.currentUser;
    final userShop = _findUserShop(user, appState.shops);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'FlowerConnect Portals',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Status',
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _refreshData,
          ),
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Mini-Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.phone,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: user.role == UserRole.admin
                                ? Colors.purple.shade50
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: user.role == UserRole.admin
                                  ? Colors.purple.shade300
                                  : AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            user.role.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: user.role == UserRole.admin
                                  ? Colors.purple.shade700
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Select Workspace Portal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose a portal matching your role and permissions.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 18),

                  // 1. CUSTOMER PORTAL CARD
                  _buildPortalCard(
                    title: 'Customer Portal',
                    subtitle: 'Explore stalls, compare morning mandi rates, broadcast custom RFQs, and track orders.',
                    icon: Icons.local_florist,
                    badgeText: 'Active & Open',
                    badgeColor: const Color(0xFF16A34A),
                    gradientColors: [const Color(0xFFDC2626), const Color(0xFFE11D48)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomerMainNav()),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // 2. VENDOR PORTAL CARD
                  _buildPortalCard(
                    title: 'Vendor & Merchant Portal',
                    subtitle: userShop == null
                        ? 'Register your flower shop, set up daily wholesale mandi rates, and submit quotations.'
                        : (userShop.isVerified
                            ? 'Manage ${userShop.name}, daily flower prices, bid on customer RFQs, and fulfill orders.'
                            : '${userShop.name} is awaiting verification by Platform Administrator.'),
                    icon: Icons.storefront_outlined,
                    badgeText: userShop == null
                        ? 'Shop Registration Needed'
                        : (userShop.isVerified ? 'Approved & Live' : 'Verification Pending'),
                    badgeColor: userShop == null
                        ? const Color(0xFFEA580C)
                        : (userShop.isVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
                    gradientColors: [const Color(0xFFD97706), const Color(0xFFB45309)],
                    onTap: () => _handleVendorPortalTap(user, appState.shops),
                  ),

                  const SizedBox(height: 16),

                  // 3. ADMIN PORTAL CARD
                  _buildPortalCard(
                    title: 'Administrator Console',
                    subtitle: 'Review & approve vendor KYC registrations, audit all RFQs and orders, and manage commissions.',
                    icon: Icons.admin_panel_settings_outlined,
                    badgeText: user.role == UserRole.admin ? 'Authorized Admin' : 'Admin Privileges Required',
                    badgeColor: user.role == UserRole.admin ? const Color(0xFF7C3AED) : const Color(0xFF6B7280),
                    gradientColors: [const Color(0xFF4C1D95), const Color(0xFF6D28D9)],
                    onTap: () => _handleAdminPortalTap(user),
                  ),

                  const SizedBox(height: 28),

                  // Security & Persistence Information Footer
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_clock_outlined, color: AppColors.primary, size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Session securely persisted with Firebase Authentication & Cloud Firestore rules.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPortalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String badgeText,
    required Color badgeColor,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
