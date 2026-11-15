import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/order_model.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/state/order_provider.dart';
import '../../core/state/auth_state_provider.dart';
import '../auth/role_switcher_sheet.dart';
import '../shared/status_badge.dart';

class DeliveryDashboardScreen extends ConsumerStatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  ConsumerState<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState
    extends ConsumerState<DeliveryDashboardScreen> {
  final Map<String, TextEditingController> _otpControllers = {};

  @override
  void dispose() {
    for (var c in _otpControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final orderState = ref.watch(orderProvider);
    final isOnline = appState.isDeliveryOnline;

    // Delivery tasks that are Home Delivery and either preparing or out for delivery
    final assignedTrips = orderState.orders.where((o) {
      return o.fulfillment == OrderFulfillment.homeDelivery &&
          (o.status == OrderStatus.outForDelivery ||
              o.status == OrderStatus.preparing ||
              o.status == OrderStatus.confirmed);
    }).toList();

    final completedTrips = orderState.orders.where((o) {
      return o.fulfillment == OrderFulfillment.homeDelivery &&
          o.status == OrderStatus.delivered;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appState.currentUser.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text(
              'Delivery Partner • Indiranagar Hub',
              style:
                  TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
            onPressed: () => RoleSwitcherSheet.show(context),
          ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Online/Offline Duty Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFFECFDF5) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOnline
                      ? const Color(0xFF10B981)
                      : AppColors.cardBorder,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isOnline
                        ? const Color(0xFF10B981)
                        : AppColors.textMuted,
                    child: Icon(
                      isOnline ? Icons.power_settings_new : Icons.bedtime,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOnline ? 'You are ONLINE' : 'You are OFFLINE',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isOnline
                                ? const Color(0xFF065F46)
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isOnline
                              ? 'Receiving nearby flower delivery requests'
                              : 'Go online to start receiving delivery runs',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isOnline,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) {
                      ref
                          .read(appStateProvider.notifier)
                          .toggleDeliveryDuty(val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Partner Earnings & Stats Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Wallet Balance',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${appState.deliveryWalletBalance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text('Instant UPI Withdrawal',
                            style: TextStyle(
                                fontSize: 9, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Trips Completed',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          '${completedTrips.length + 8}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        const Text('4.9 ★ Driver Rating',
                            style: TextStyle(
                                fontSize: 9, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Active Trips Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assigned Flower Deliveries',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${assignedTrips.length} active',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (!isOnline)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Center(
                  child: Text(
                    'You are offline. Turn switch on above to view active trips.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else if (assignedTrips.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Center(
                  child: Text(
                    'No active delivery assignments. You are on standby for nearby orders.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...assignedTrips.map((order) {
                if (!_otpControllers.containsKey(order.id)) {
                  _otpControllers[order.id] = TextEditingController();
                }
                final otpController = _otpControllers[order.id]!;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.id,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          StatusBadge.fromOrderStatus(order.status),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // PICKUP LOCATION
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.store,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('PICKUP FROM',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMuted)),
                                Text(order.shopName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                const Text(
                                    'Indiranagar 100ft Rd, Bangalore',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.navigation,
                                color: Color(0xFF0284C7)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Opening Google Maps route to ${order.shopName}...'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: SizedBox(
                          height: 20,
                          child: VerticalDivider(
                              width: 1, color: AppColors.divider),
                        ),
                      ),

                      // DROP-OFF LOCATION
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.home,
                              color: Color(0xFF1E293B), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('DELIVER TO',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMuted)),
                                Text(
                                  order.isSurpriseDelivery
                                      ? 'SURPRISE: ${order.surpriseRecipientName} (c/o ${order.customerName})'
                                      : order.customerName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                Text(order.deliveryAddress,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.call,
                                color: Color(0xFF059669)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Calling customer: ${order.customerPhone}'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      // OTP Handover Verification Field
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_user,
                                    color: AppColors.accent, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Delivery Verification OTP',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Ask customer for their 4-digit code (Demo code: 4821 or 0000)',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: otpController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter 4-digit OTP',
                                      counterText: '',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    final otp = otpController.text.trim();
                                    final success = ref
                                        .read(orderProvider.notifier)
                                        .verifyOtpAndCompleteDelivery(
                                          order.id,
                                          otp,
                                        );

                                    if (success) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Order ${order.id} delivered successfully! +₹${(order.deliveryFee + 20).toStringAsFixed(0)} credited to wallet.'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: AppColors.accent,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Invalid OTP. Please check with customer or enter 4821 / 0000.'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                  ),
                                  child: const Text('Verify & Finish',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

