import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/order_model.dart';
import '../../core/models/rfq_model.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/state/order_provider.dart';
import '../../core/state/rfq_provider.dart';
import '../../core/state/auth_state_provider.dart';
import '../shared/status_badge.dart';
import 'submit_quotation_dialog.dart';
import 'daily_price_manager_screen.dart';

class MerchantDashboardScreen extends ConsumerStatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  ConsumerState<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends ConsumerState<MerchantDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(appStateProvider).currentUser;
      ref.read(rfqProvider.notifier).refreshFromFirestore();
      if (user.shopId != null) {
        ref.read(orderProvider.notifier).refreshFromFirestore(shopId: user.shopId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final orderState = ref.watch(orderProvider);
    final rfqState = ref.watch(rfqProvider);

    final user = appState.currentUser;
    final shop = appState.shops.firstWhere(
      (s) => s.id == user.shopId,
      orElse: () => appState.shops.first,
    );

    // Filter incoming RFQs for this merchant type
    final nearbyRFQs = rfqState.requests.where((r) {
      return r.status == RFQStatus.broadcasting ||
          r.status == RFQStatus.quotesReceived;
    }).toList();

    // Orders placed for this shop
    final shopOrders = orderState.orders.where((o) => o.shopId == shop.id).toList();

    // Calculate revenue
    final totalRevenue = shopOrders
        .where((o) => o.status != OrderStatus.cancelled)
        .fold(0.0, (sum, o) => sum + (o.grandTotal - o.platformCommission));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              'Owner: ${user.name} • ${shop.typeLabel}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Switch Portal',
            icon: const Icon(Icons.apps, color: AppColors.primary),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
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
            // Analytics Row
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
                        const Text('Net Revenue', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${totalRevenue.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        const Text('After platform fee', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
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
                        const Text('Shop Rating', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              shop.rating.toString(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.star, color: Color(0xFF059669), size: 16),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('${shop.totalReviews} verified reviews', style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
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
                        const Text('Orders', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          '${shopOrders.length}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        const Text('Today\'s Pipeline', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Daily Wholesale Rate Quick Manager Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.currency_rupee, color: AppColors.amber, size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Daily Wholesale Flower Rates',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Broadcast fresh morning prices for Jasmine, Roses, Marigolds to nearby buyers.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DailyPriceManagerScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Update', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // INCOMING CUSTOMER RFQS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Incoming Customer RFQs (Within 5km)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${nearbyRFQs.length} active',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (nearbyRFQs.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Center(
                  child: Text(
                    'No pending RFQs right now. You will be notified when customers nearby broadcast requirements.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...nearbyRFQs.map((rfq) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
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
                          StatusBadge.fromRFQStatus(rfq.status),
                          Text(
                            rfq.deliveryPreference == DeliveryPreference.homeDelivery
                                ? '🚚 Home Delivery'
                                : '🏬 Self-Pickup',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rfq.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Details: ${rfq.quantityDescription}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '📍 Delivery to: ${rfq.deliveryAddress}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (rfq.targetBudget != null)
                            Text(
                              'Target Budget: ₹${rfq.targetBudget!.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 12),
                            )
                          else
                            const SizedBox(),
                          ElevatedButton.icon(
                            onPressed: () {
                              SubmitQuotationDialog.show(context, rfq);
                            },
                            icon: const Icon(Icons.gavel, size: 14),
                            label: const Text('Submit Quotation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 20),

            // ACTIVE ORDERS PIPELINE
            const Text(
              'Active Orders & Fulfillment',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            if (shopOrders.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Center(
                  child: Text('No active orders right now.', style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              ...shopOrders.map((order) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          StatusBadge.fromOrderStatus(order.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Customer: ${order.customerName} (${order.customerPhone})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Items: ${order.items.map((i) => "${i.quantity}x ${i.productName}").join(", ")}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount: ₹${order.grandTotal.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          Text(
                            'Payment: ${order.paymentMethod.name.toUpperCase()} (${order.paymentStatus.name})',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Merchant Action Buttons
                      Wrap(
                        spacing: 8,
                        children: [
                          if (order.status == OrderStatus.placed)
                            ElevatedButton(
                              onPressed: () {
                                ref.read(orderProvider.notifier).updateOrderStatus(order.id, OrderStatus.confirmed);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: const Text('Accept Order', style: TextStyle(fontSize: 11)),
                            ),
                          if (order.status == OrderStatus.confirmed)
                            ElevatedButton(
                              onPressed: () {
                                ref.read(orderProvider.notifier).updateOrderStatus(order.id, OrderStatus.preparing);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber),
                              child: const Text('Start Preparing', style: TextStyle(fontSize: 11)),
                            ),
                          if (order.status == OrderStatus.preparing)
                            ElevatedButton(
                              onPressed: () {
                                ref.read(orderProvider.notifier).updateOrderStatus(
                                      order.id,
                                      order.fulfillment == OrderFulfillment.selfPickup
                                          ? OrderStatus.readyForPickup
                                          : OrderStatus.outForDelivery,
                                    );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                              child: Text(
                                order.fulfillment == OrderFulfillment.selfPickup
                                    ? 'Mark Ready for Pickup'
                                    : 'Handover to Delivery Partner',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                        ],
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
