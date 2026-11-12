import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flower_connect/core/models/order_model.dart';
import 'package:flower_connect/core/models/rfq_model.dart';
import 'package:flower_connect/core/state/rfq_provider.dart';
import 'package:flower_connect/core/state/cart_provider.dart';
import 'package:flower_connect/core/state/order_provider.dart';
import 'package:flower_connect/core/constants/demo_data.dart';

void main() {
  test('Unit Test - Cart calculation and fulfillment logic', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cartNotifier = container.read(cartProvider.notifier);
    final product = DemoData.products[0];

    // Add to cart
    cartNotifier.addToCart(product);
    var state = container.read(cartProvider);
    expect(state.totalItemCount, 1);
    expect(state.itemsTotal, product.price);
    expect(state.deliveryFee, 40.0);
    expect(state.grandTotal, product.price + 40.0 + 15.0);

    // Switch to Self-Pickup
    cartNotifier.setFulfillment(OrderFulfillment.selfPickup);
    state = container.read(cartProvider);
    expect(state.deliveryFee, 0.0);
    expect(state.grandTotal, product.price + 0.0 + 15.0);
  });

  test('Unit Test - Dynamic Quotation System (Bidding & Single-Winner Lock)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final rfqNotifier = container.read(rfqProvider.notifier);

    // Create RFQ
    final rfq = rfqNotifier.createRFQ(
      customerId: 'test_cust',
      customerName: 'Test Customer',
      title: '100 Roses for Gala',
      flowerType: 'Roses',
      quantityDescription: '100 red roses',
      deliveryPreference: DeliveryPreference.homeDelivery,
      deliveryAddress: 'MG Road, Bangalore',
      targetBudget: 3500.0,
      needBy: DateTime.now().add(const Duration(hours: 4)),
    );

    expect(rfq.status, RFQStatus.broadcasting);

    // Merchant 1 submits quote
    rfqNotifier.submitQuotation(
      rfqId: rfq.id,
      merchantId: 'shop_001',
      shopName: 'Sri Lakshmi Flower Stall',
      merchantPhone: '+91 98450 12345',
      merchantRating: 4.8,
      distanceKm: 1.2,
      quotedPrice: 3200.0,
      deliveryFee: 40.0,
      prepTimeMinutes: 30,
      notes: 'Morning fresh harvest',
      freshnessGuarantee: 'Guaranteed 5-day freshness',
    );

    // Merchant 2 submits quote
    rfqNotifier.submitQuotation(
      rfqId: rfq.id,
      merchantId: 'shop_002',
      shopName: 'Petals & Blooms Studio',
      merchantPhone: '+91 98451 98765',
      merchantRating: 4.9,
      distanceKm: 2.5,
      quotedPrice: 3600.0,
      deliveryFee: 50.0,
      prepTimeMinutes: 25,
      notes: 'Imported Grade-A Dutch roses',
      freshnessGuarantee: 'Floral nutrient booster included',
    );

    final quotes = container.read(rfqProvider).quotationsMap[rfq.id]!;
    expect(quotes.length, 2);

    // Customer accepts Merchant 1's quotation
    final winningQuote = quotes[0];
    final order = rfqNotifier.acceptQuotation(
      rfqId: rfq.id,
      quotationId: winningQuote.id,
    );

    expect(order, isNotNull);
    expect(order!.shopId, 'shop_001');

    // Verify RFQ is locked as accepted
    final updatedRfq = container.read(rfqProvider).requests.firstWhere((r) => r.id == rfq.id);
    expect(updatedRfq.status, RFQStatus.accepted);
    expect(updatedRfq.acceptedQuotationId, winningQuote.id);

    // Verify order was pushed to OrderProvider
    final orders = container.read(orderProvider).orders;
    expect(orders.any((o) => o.id == order.id), isTrue);
  });
}
