import 'package:flutter/material.dart';
import '../../core/models/order_model.dart';
import '../../core/models/rfq_model.dart';
import '../../core/models/quotation_model.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.fromOrderStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return const StatusBadge(
          label: 'Order Placed',
          backgroundColor: Color(0xFFFEF3C7),
          textColor: Color(0xFFD97706),
          icon: Icons.receipt_long,
        );
      case OrderStatus.confirmed:
        return const StatusBadge(
          label: 'Confirmed',
          backgroundColor: Color(0xFFEDE9FE),
          textColor: Color(0xFF7C3AED),
          icon: Icons.check_circle_outline,
        );
      case OrderStatus.preparing:
        return const StatusBadge(
          label: 'Preparing',
          backgroundColor: Color(0xFFFFE4E6),
          textColor: Color(0xFFE11D48),
          icon: Icons.local_florist,
        );
      case OrderStatus.outForDelivery:
        return const StatusBadge(
          label: 'Out for Delivery',
          backgroundColor: Color(0xFFE0F2FE),
          textColor: Color(0xFF0284C7),
          icon: Icons.delivery_dining,
        );
      case OrderStatus.readyForPickup:
        return const StatusBadge(
          label: 'Ready for Pickup',
          backgroundColor: Color(0xFFDCFCE7),
          textColor: Color(0xFF16A34A),
          icon: Icons.storefront,
        );
      case OrderStatus.delivered:
        return const StatusBadge(
          label: 'Delivered',
          backgroundColor: Color(0xFFDCFCE7),
          textColor: Color(0xFF16A34A),
          icon: Icons.task_alt,
        );
      case OrderStatus.cancelled:
        return const StatusBadge(
          label: 'Cancelled',
          backgroundColor: Color(0xFFFEE2E2),
          textColor: Color(0xFFDC2626),
          icon: Icons.cancel_outlined,
        );
    }
  }

  factory StatusBadge.fromRFQStatus(RFQStatus status) {
    switch (status) {
      case RFQStatus.broadcasting:
        return const StatusBadge(
          label: 'Broadcasting to Shops',
          backgroundColor: Color(0xFFFEF3C7),
          textColor: Color(0xFFD97706),
          icon: Icons.sensors,
        );
      case RFQStatus.quotesReceived:
        return const StatusBadge(
          label: 'Quotes Received',
          backgroundColor: Color(0xFFE0F2FE),
          textColor: Color(0xFF0284C7),
          icon: Icons.mark_email_unread,
        );
      case RFQStatus.accepted:
        return const StatusBadge(
          label: 'Quote Accepted & Locked',
          backgroundColor: Color(0xFFDCFCE7),
          textColor: Color(0xFF16A34A),
          icon: Icons.lock,
        );
      case RFQStatus.expired:
        return const StatusBadge(
          label: 'Expired',
          backgroundColor: Color(0xFFF1F5F9),
          textColor: Color(0xFF64748B),
          icon: Icons.timer_off,
        );
      case RFQStatus.cancelled:
        return const StatusBadge(
          label: 'Cancelled',
          backgroundColor: Color(0xFFFEE2E2),
          textColor: Color(0xFFDC2626),
          icon: Icons.close,
        );
    }
  }

  factory StatusBadge.fromQuotationStatus(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.pending:
        return const StatusBadge(
          label: 'Active Bid',
          backgroundColor: Color(0xFFEDE9FE),
          textColor: Color(0xFF7C3AED),
          icon: Icons.schedule,
        );
      case QuotationStatus.accepted:
        return const StatusBadge(
          label: 'Winning Offer',
          backgroundColor: Color(0xFFDCFCE7),
          textColor: Color(0xFF16A34A),
          icon: Icons.military_tech,
        );
      case QuotationStatus.rejected:
        return const StatusBadge(
          label: 'Not Selected',
          backgroundColor: Color(0xFFF1F5F9),
          textColor: Color(0xFF94A3B8),
          icon: Icons.block,
        );
      case QuotationStatus.expired:
        return const StatusBadge(
          label: 'Expired',
          backgroundColor: Color(0xFFFEE2E2),
          textColor: Color(0xFFDC2626),
          icon: Icons.timer_off,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
