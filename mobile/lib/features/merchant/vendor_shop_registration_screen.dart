import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../core/models/shop_model.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/state/auth_state_provider.dart';
import '../../core/services/firestore_service.dart';
import '../auth/vendor_approval_pending_screen.dart';

class VendorShopRegistrationScreen extends ConsumerStatefulWidget {
  const VendorShopRegistrationScreen({super.key});

  @override
  ConsumerState<VendorShopRegistrationScreen> createState() =>
      _VendorShopRegistrationScreenState();
}

class _VendorShopRegistrationScreenState
    extends ConsumerState<VendorShopRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  ShopType _selectedShopType = ShopType.flowerShop;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(appStateProvider).currentUser;
    _shopNameController.text = '${user.name} Flowers';
    _addressController.text = user.address.isNotEmpty
        ? user.address
        : 'Indiranagar 100ft Road, Bengaluru';
    _phoneController.text = user.phone;
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  UserRole _resolveMerchantRole(ShopType type) {
    switch (type) {
      case ShopType.flowerShop:
        return UserRole.flowerMerchant;
      case ShopType.bouquetShop:
        return UserRole.bouquetMerchant;
      case ShopType.giftShop:
        return UserRole.giftMerchant;
      case ShopType.hybrid:
        return UserRole.flowerMerchant;
    }
  }

  Future<void> _submitShopRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(appStateProvider).currentUser;
      final shopId = 'shop_${DateTime.now().millisecondsSinceEpoch}';
      final role = _resolveMerchantRole(_selectedShopType);

      final initialRates = <String, double>{
        'Jasmine (Gundu Mallige)': 280.0,
        'Red Dutch Roses': 180.0,
        'Marigold (Sevanthige)': 120.0,
        'Carnations': 220.0,
      };

      final newShop = ShopModel(
        id: shopId,
        userId: user.id, // Strictly bound to authenticated UID
        name: _shopNameController.text.trim(),
        type: _selectedShopType,
        address: _addressController.text.trim(),
        rating: 4.8,
        totalReviews: 0,
        distanceKm: 1.2,
        etaMinutes: 20,
        imageUrl:
            'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=600&q=80',
        isVerified: false, // Mandatory: unverified until Admin approvals
        isFeatured: false,
        isOpen: false,
        ownerName: user.name,
        contactPhone: _phoneController.text.trim(),
        dailyRates: initialRates,
      );

      // 1. Write shop to Cloud Firestore
      await FirestoreService.createShop(newShop);

      // 2. Update user profile with shopId and vendor role in Firestore
      final updatedUser = user.copyWith(
        shopId: shopId,
        role: role,
        isVendorApproved: false,
      );
      await FirestoreService.saveUserProfile(updatedUser);

      // 3. Update in-memory providers
      ref.read(appStateProvider.notifier).registerNewShop(newShop);
      ref.read(appStateProvider.notifier).setCurrentUser(updatedUser);
      ref.read(authStateProvider.notifier).setCurrentUser(updatedUser);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shop "${newShop.name}" submitted! Awaiting Admin verification.'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );

      // 4. Navigate directly to Vendor Approval Pending screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VendorApprovalPendingScreen(shop: newShop),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration notice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Register Flower Stall',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: Color(0xFFD97706), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Verification Required',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'To protect buyers, newly registered flower shops are reviewed by the Platform Admin before bidding on RFQs.',
                            style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Shop Name
              const Text('Shop / Stall Name',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _shopNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Sri Lakshmi Flower Stall',
                  prefixIcon: Icon(Icons.store, color: AppColors.textSecondary),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter your shop or stall name'
                    : null,
              ),

              const SizedBox(height: 16),

              // Category Selector
              const Text('Stall Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<ShopType>(
                value: _selectedShopType,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category, color: AppColors.textSecondary),
                ),
                items: const [
                  DropdownMenuItem(
                    value: ShopType.flowerShop,
                    child: Text('Traditional Flower Stall (Loose Flowers & Mandi Stems)'),
                  ),
                  DropdownMenuItem(
                    value: ShopType.bouquetShop,
                    child: Text('Bouquet Studio (Arrangements & Events)'),
                  ),
                  DropdownMenuItem(
                    value: ShopType.giftShop,
                    child: Text('Gift & Floral Boutique (Hampers & Combos)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedShopType = val);
                },
              ),

              const SizedBox(height: 16),

              // Address
              const Text('Physical Location / Mandi Address',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Stall #14, Indiranagar Flower Market, Bengaluru',
                  prefixIcon: Icon(Icons.location_on, color: AppColors.textSecondary),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter your stall address'
                    : null,
              ),

              const SizedBox(height: 16),

              // Contact Phone
              const Text('Contact Mobile Number',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+91 98450 12345',
                  prefixIcon: Icon(Icons.phone, color: AppColors.textSecondary),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter a contact number'
                    : null,
              ),

              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitShopRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit for Admin Approval',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
