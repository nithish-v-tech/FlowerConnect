import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/state/auth_state_provider.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/models/shop_model.dart';

class VendorApprovalPendingScreen extends ConsumerWidget {
  const VendorApprovalPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final appState = ref.watch(appStateProvider);
    final user = authState.currentUser;

    // Find the vendor's shop
    final shop = appState.shops.firstWhere(
      (s) => s.id == user?.shopId,
      orElse: () => ShopModel(
        id: 'shop_pending',
        name: '${user?.name ?? 'Vendor'} Stall',
        type: ShopType.flowerShop,
        address: user?.address ?? 'Bengaluru',
        rating: 0.0,
        totalReviews: 0,
        distanceKm: 0.0,
        etaMinutes: 0,
        imageUrl: '',
        isVerified: false,
        isOpen: false,
        ownerName: user?.name ?? 'Vendor',
        contactPhone: user?.phone ?? '',
        dailyRates: {},
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vendor Onboarding',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Header Illustration / Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDE68A), width: 3),
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 64,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 20),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pending_actions, size: 16, color: Color(0xFFB45309)),
                  SizedBox(width: 6),
                  Text(
                    'APPROVAL PENDING',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            const Text(
              'Your Vendor Application is Under Review',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'To protect customers and maintain superior floral quality, all merchant shops undergo review by FlowerConnect Admin before receiving customer orders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Shop Information Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Application Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Divider(height: 20),
                  _detailRow(Icons.store, 'Shop Name', shop.name),
                  const SizedBox(height: 10),
                  _detailRow(Icons.category, 'Shop Category', shop.typeLabel),
                  const SizedBox(height: 10),
                  _detailRow(Icons.person, 'Applicant Owner', shop.ownerName),
                  const SizedBox(height: 10),
                  _detailRow(Icons.phone, 'Contact Mobile', shop.contactPhone),
                  const SizedBox(height: 10),
                  _detailRow(Icons.location_on, 'Location', shop.address),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Verification Steps
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verification Milestones',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  _stepRow(
                    stepNumber: '1',
                    title: 'Phone Number & OTP Verification',
                    description: 'Identity authenticated successfully.',
                    isDone: true,
                  ),
                  _stepRow(
                    stepNumber: '2',
                    title: 'Shop Registration & Geolocation',
                    description: 'Hyperlocal service radius configured.',
                    isDone: true,
                  ),
                  _stepRow(
                    stepNumber: '3',
                    title: 'Admin KYC & License Approval',
                    description: 'Platform Admin is reviewing your stall credentials.',
                    isDone: false,
                    isCurrent: true,
                  ),
                  _stepRow(
                    stepNumber: '4',
                    title: 'Live Catalog & RFQ Bidding Access',
                    description: 'Unlock daily price management & incoming orders.',
                    isDone: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Demo Admin Switch Tip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Demo Tip: Instant Admin Approval',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'You can log out and log in as Super Admin (+91 90000 00001) to verify this shop with one tap!',
                          style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Check Approval Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                onPressed: () {
                  // Re-evaluate verification status
                  if (shop.isVerified) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Congratulations! Your shop has been approved!'),
                        backgroundColor: Color(0xFF16A34A),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Approval is still pending. Please check back shortly.'),
                        backgroundColor: Color(0xFFD97706),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout, color: AppColors.textSecondary),
                label: const Text(
                  'Switch Account or Log Out',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                onPressed: () {
                  ref.read(authStateProvider.notifier).logout();
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepRow({
    required String stepNumber,
    required String title,
    required String description,
    required bool isDone,
    bool isCurrent = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? const Color(0xFF16A34A)
                  : (isCurrent ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      stepNumber,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? Colors.white : AppColors.textMuted,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                    color: isCurrent ? const Color(0xFFB45309) : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

