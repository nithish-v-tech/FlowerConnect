import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/rfq_model.dart';
import '../../core/models/quotation_model.dart';
import '../../core/state/rfq_provider.dart';
import '../shared/status_badge.dart';
import '../shared/quotation_bid_card.dart';
import '../customer/order_tracking_screen.dart';

enum QuoteSortOption {
  lowestPrice,
  nearestDistance,
  highestRating,
  fastestETA,
}

class QuotationComparisonScreen extends ConsumerStatefulWidget {
  final String rfqId;

  const QuotationComparisonScreen({super.key, required this.rfqId});

  @override
  ConsumerState<QuotationComparisonScreen> createState() =>
      _QuotationComparisonScreenState();
}

class _QuotationComparisonScreenState
    extends ConsumerState<QuotationComparisonScreen> {
  QuoteSortOption _selectedSort = QuoteSortOption.lowestPrice;

  @override
  Widget build(BuildContext context) {
    final rfqState = ref.watch(rfqProvider);

    final rfqIndex = rfqState.requests.indexWhere((r) => r.id == widget.rfqId);
    if (rfqIndex < 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quotations')),
        body: const Center(child: Text('RFQ request not found.')),
      );
    }

    final rfq = rfqState.requests[rfqIndex];
    final quotations = List<QuotationModel>.from(
        rfqState.quotationsMap[widget.rfqId] ?? []);

    // Sort quotations
    quotations.sort((a, b) {
      switch (_selectedSort) {
        case QuoteSortOption.lowestPrice:
          return a.grandTotal.compareTo(b.grandTotal);
        case QuoteSortOption.nearestDistance:
          return a.distanceKm.compareTo(b.distanceKm);
        case QuoteSortOption.highestRating:
          return b.merchantRating.compareTo(a.merchantRating);
        case QuoteSortOption.fastestETA:
          return a.prepTimeMinutes.compareTo(b.prepTimeMinutes);
      }
    });

    final isAnyAccepted = rfq.status == RFQStatus.accepted;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Compare Merchant Quotes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              '${quotations.length} offers received',
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Dynamic Quotation Guarantee'),
                  content: const Text(
                    'FlowerConnect lets nearby florists submit competing real-time bids for your floral order.\n\nOnce you accept 1 quotation, it locks in the price, automatically cancels competing bids to avoid duplicate orders, and confirms your order with the winning florist.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // RFQ Details Header Card
            Container(
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
                      StatusBadge.fromRFQStatus(rfq.status),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            rfq.isExpired ? 'Bidding Closed' : 'Expires in 35m',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rfq.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🌸 ${rfq.quantityDescription}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        rfq.deliveryPreference == DeliveryPreference.homeDelivery
                            ? Icons.delivery_dining
                            : Icons.storefront,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rfq.deliveryPreference == DeliveryPreference.homeDelivery
                            ? 'Home Delivery'
                            : 'Self-Pickup',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      if (rfq.targetBudget != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '🎯 Target: ₹${rfq.targetBudget!.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sorting Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sort Offers by:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                DropdownButton<QuoteSortOption>(
                  value: _selectedSort,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort,
                      color: AppColors.primary, size: 18),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSort = val);
                  },
                  items: const [
                    DropdownMenuItem(
                      value: QuoteSortOption.lowestPrice,
                      child: Text('Lowest Total Price'),
                    ),
                    DropdownMenuItem(
                      value: QuoteSortOption.nearestDistance,
                      child: Text('Nearest Distance'),
                    ),
                    DropdownMenuItem(
                      value: QuoteSortOption.highestRating,
                      child: Text('Merchant Rating'),
                    ),
                    DropdownMenuItem(
                      value: QuoteSortOption.fastestETA,
                      child: Text('Fastest Prep Time'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Competing Quotation Cards
            if (quotations.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Broadcasting to local florists...\nQuotations typically arrive within 2-5 minutes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ...quotations.map((quote) {
                final isWinning = rfq.acceptedQuotationId == quote.id;
                return QuotationBidCard(
                  quotation: quote,
                  isWinningQuote: isWinning,
                  isAnyQuoteAccepted: isAnyAccepted,
                  onAccept: () {
                    final confirmedOrder = ref
                        .read(rfqProvider.notifier)
                        .acceptQuotation(
                          rfqId: rfq.id,
                          quotationId: quote.id,
                        );

                    if (confirmedOrder != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Quotation accepted! Order confirmed with ${quote.shopName}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(
                            orderId: confirmedOrder.id,
                          ),
                        ),
                      );
                    }
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}

