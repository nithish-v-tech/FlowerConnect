import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/state/app_state_provider.dart';

class RoleSwitcherSheet extends ConsumerWidget {
  const RoleSwitcherSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const RoleSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final currentRole = appState.currentUser.role;

    final roles = [
      (
        UserRole.customer,
        'Customer Mode',
        'Explore flowers, build custom bouquets, create RFQs & live track orders',
        Icons.person,
        AppColors.primary,
      ),
      (
        UserRole.flowerMerchant,
        'Flower Merchant (Sri Lakshmi)',
        'Manage roadside fresh flower stall, daily kg rates, bid on RFQs',
        Icons.local_florist,
        const Color(0xFFE11D48),
      ),
      (
        UserRole.bouquetMerchant,
        'Bouquet Merchant (Petals Studio)',
        'Boutique florist, accept custom arrangement quotes & manage orders',
        Icons.spa,
        const Color(0xFF7C3AED),
      ),
      (
        UserRole.giftMerchant,
        'Gift Merchant (The Velvet Ribbon)',
        'Gift hampers, cards, chocolates, surprise delivery coordinator',
        Icons.card_giftcard,
        const Color(0xFFD97706),
      ),
      (
        UserRole.deliveryPartner,
        'Delivery Partner (Ramesh G.)',
        'Online/offline duty, accept pickups, turn-by-turn map & OTP delivery',
        Icons.delivery_dining,
        const Color(0xFF0284C7),
      ),
      (
        UserRole.admin,
        'Super Admin Portal',
        'Manage commissions, merchants KYC, dispute resolution & ledger',
        Icons.admin_panel_settings,
        const Color(0xFF059669),
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.switch_account, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Switch Operating Role',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Select any of the 6 roles to experience all marketplace workflows live.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 18),
          ...roles.map((item) {
            final role = item.$1;
            final title = item.$2;
            final desc = item.$3;
            final icon = item.$4;
            final color = item.$5;
            final isSelected = currentRole == role;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? color : AppColors.cardBorder,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  ref.read(appStateProvider.notifier).switchRole(role);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched to ${role.label}'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color, size: 22),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: color)
                    : const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
              ),
            );
          }),
        ],
      ),
    );
  }
}

