import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flower_connect/core/models/order_model.dart';
import 'package:flower_connect/core/models/rfq_model.dart';
import 'package:flower_connect/core/state/rfq_provider.dart';
import 'package:flower_connect/core/state/cart_provider.dart';
import 'package:flower_connect/core/state/order_provider.dart';
import 'package:flower_connect/core/models/user_model.dart';
import 'package:flower_connect/core/models/shop_model.dart';
import 'package:flower_connect/core/state/auth_state_provider.dart';
import 'package:flower_connect/core/state/app_state_provider.dart';
import 'package:flower_connect/core/constants/demo_data.dart';
import 'package:flower_connect/core/services/api_service.dart';
import 'package:flower_connect/main.dart';
import 'package:flower_connect/features/auth/login_screen.dart';
import 'package:flower_connect/features/portal/portal_selection_screen.dart';

void main() {
  setUp(() {
    ApiService.requestTimeout = const Duration(milliseconds: 30);
  });
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

  test('Unit Test - Phase 1: Common Mobile OTP Authentication & Role Navigation', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final authNotifier = container.read(authStateProvider.notifier);

    // Initial state: not authenticated
    expect(container.read(authStateProvider).isAuthenticated, isFalse);

    // 1. Send OTP to valid 10-digit mobile
    final otpSent = await authNotifier.sendOtp('9876543210');
    expect(otpSent, isTrue);
    expect(container.read(authStateProvider).isOtpSent, isTrue);
    expect(container.read(authStateProvider).phoneNumber, '+919876543210');

    // 2. Verify with invalid OTP should fail
    final badOtp = await authNotifier.verifyOtp('000000');
    expect(badOtp, isFalse);
    expect(container.read(authStateProvider).errorMessage, isNotNull);

    // 3. Verify with valid OTP for Customer
    final verified = await authNotifier.verifyOtp('123456');
    expect(verified, isTrue);
    expect(container.read(authStateProvider).isAuthenticated, isTrue);
    expect(container.read(authStateProvider).currentUser?.role, UserRole.customer);
    expect(container.read(appStateProvider).currentUser.role, UserRole.customer);

    // 4. Logout
    authNotifier.logout();
    expect(container.read(authStateProvider).isAuthenticated, isFalse);
  });

  test('Unit Test - Phase 1: Pending Vendor State & Admin Instant Approval', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final authNotifier = container.read(authStateProvider.notifier);
    final appNotifier = container.read(appStateProvider.notifier);

    // Quick login as Pending Vendor
    authNotifier.quickLogin('+919999988888');
    final authState = container.read(authStateProvider);
    expect(authState.isAuthenticated, isTrue);
    expect(authState.currentUser?.shopId, 'shop_pending_01');

    // Verify shop is initially pending (unverified)
    final pendingShop = container.read(appStateProvider).shops.firstWhere((s) => s.id == 'shop_pending_01');
    expect(pendingShop.isVerified, isFalse);

    // Admin approves the shop
    appNotifier.approveVendor('shop_pending_01');

    // Verify shop is now verified and active
    final approvedShop = container.read(appStateProvider).shops.firstWhere((s) => s.id == 'shop_pending_01');
    expect(approvedShop.isVerified, isTrue);
    expect(approvedShop.isOpen, isTrue);
  });

  test('Unit Test - Phase 1: Strict Admin Security (Self-assignment forbidden)', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final authNotifier = container.read(authStateProvider.notifier);

    // Try to register as Admin
    final adminAttempt = await authNotifier.registerProfile(
      fullName: 'Attacker Admin',
      role: UserRole.admin, // MUST BE REJECTED
    );

    expect(adminAttempt, isFalse);
    expect(container.read(authStateProvider).errorMessage, contains('forbidden'));
    expect(container.read(authStateProvider).isAuthenticated, isFalse);

    // Register as new vendor -> creates pending shop
    await authNotifier.sendOtp('9123456789');
    final vendorSuccess = await authNotifier.registerProfile(
      fullName: 'New Florist',
      role: UserRole.flowerMerchant,
      shopName: 'Green Petals Stall',
      shopType: ShopType.flowerShop,
      shopAddress: 'Jayanagar 4th Block',
    );

    expect(vendorSuccess, isTrue);
    expect(container.read(authStateProvider).isAuthenticated, isTrue);
    final newShopId = container.read(authStateProvider).currentUser?.shopId;
    expect(newShopId, isNotNull);

    // Ensure new vendor shop defaults to unverified (pending admin approval)
    final newShop = container.read(appStateProvider).shops.firstWhere((s) => s.id == newShopId);
    expect(newShop.isVerified, isFalse);
  });

  testWidgets('App launch and portal routing test - starts on LoginScreen and routes to PortalSelectionScreen upon auth', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FlowerConnectApp(),
      ),
    );
    await tester.pump();

    // 1. Verify initial launch screen is LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(PortalSelectionScreen), findsNothing);
    expect(find.text('Mobile Number Login'), findsOneWidget);
    expect(find.text('Firebase Spark Plan Test Accounts'), findsOneWidget);

    // 2. Authenticate user
    container.read(authStateProvider.notifier).quickLogin('+919876543210');
    await tester.pumpAndSettle();

    // 3. Verify screen re-routes to PortalSelectionScreen
    expect(find.byType(PortalSelectionScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('FlowerConnect Portals'), findsOneWidget);
    expect(find.text('Customer Portal'), findsOneWidget);
    expect(find.text('Vendor & Merchant Portal'), findsOneWidget);
    expect(find.text('Administrator Console'), findsOneWidget);
  });
}
