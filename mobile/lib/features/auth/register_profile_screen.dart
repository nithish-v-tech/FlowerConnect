import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../core/models/shop_model.dart';
import '../../core/state/auth_state_provider.dart';
import '../portal/portal_selection_screen.dart';

class RegisterProfileScreen extends ConsumerStatefulWidget {
  const RegisterProfileScreen({super.key});

  @override
  ConsumerState<RegisterProfileScreen> createState() =>
      _RegisterProfileScreenState();
}

class _RegisterProfileScreenState extends ConsumerState<RegisterProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();

  UserRole _selectedRole = UserRole.customer;
  ShopType _selectedShopType = ShopType.flowerShop;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    super.dispose();
  }

  bool get _isVendorRole =>
      _selectedRole == UserRole.flowerMerchant ||
      _selectedRole == UserRole.bouquetMerchant ||
      _selectedRole == UserRole.giftMerchant;

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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authStateProvider.notifier);
    final roleToAssign = _isVendorRole
        ? _resolveMerchantRole(_selectedShopType)
        : _selectedRole;

    final success = await authNotifier.registerProfile(
      fullName: _nameController.text.trim(),
      role: roleToAssign,
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      shopName: _isVendorRole ? _shopNameController.text.trim() : null,
      shopType: _isVendorRole ? _selectedShopType : null,
      shopAddress: _isVendorRole ? _shopAddressController.text.trim() : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isVendorRole
              ? 'Vendor registered! Sent to Admin for verification.'
              : 'Welcome to FlowerConnect, ${_nameController.text.trim()}!'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PortalSelectionScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Your Profile',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phone Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_android, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      authState.phoneNumber ?? '+91 ...',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Full Name
              const Text('Full Name *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Ramesh Kumar',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email
              const Text('Email Address (Optional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'e.g. ramesh@example.com',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Account Role Selection
              const Text('Select Your Account Role *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              const Text(
                'Choose how you want to participate in the FlowerConnect hyperlocal ecosystem:',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              // Customer Option
              _roleCard(
                title: 'Customer',
                subtitle: 'Browse nearby stalls, order bouquets & gifts, request custom quotations',
                icon: Icons.shopping_bag_outlined,
                isSelected: _selectedRole == UserRole.customer,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.customer;
                  });
                },
              ),

              const SizedBox(height: 10),

              // Vendor Option
              _roleCard(
                title: 'Shop Partner / Merchant',
                subtitle: 'Roadside flower stall, bouquet florist or gift shop wanting to sell & bid',
                icon: Icons.storefront_outlined,
                isSelected: _isVendorRole,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.flowerMerchant;
                  });
                },
              ),

              const SizedBox(height: 10),

              // Delivery Partner Option
              _roleCard(
                title: 'Delivery Partner',
                subtitle: 'Earn delivering hyperlocal flower & gift orders directly from local shops',
                icon: Icons.delivery_dining_outlined,
                isSelected: _selectedRole == UserRole.deliveryPartner,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.deliveryPartner;
                  });
                },
              ),

              // Expanded Vendor Shop Details if Vendor is selected
              if (_isVendorRole) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.store, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Shop Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Shop Name
                      const Text('Shop / Stall Name *',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _shopNameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Sri Balaji Fresh Flowers',
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        validator: (val) {
                          if (_isVendorRole && (val == null || val.trim().isEmpty)) {
                            return 'Please enter your shop or stall name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // Shop Category
                      const Text('Shop Type *',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Local Flower Stall'),
                            selected: _selectedShopType == ShopType.flowerShop,
                            selectedColor: AppColors.primaryLight,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedShopType = ShopType.flowerShop);
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Artisan Bouquet Studio'),
                            selected: _selectedShopType == ShopType.bouquetShop,
                            selectedColor: AppColors.primaryLight,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedShopType = ShopType.bouquetShop);
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Gifts & Chocolates'),
                            selected: _selectedShopType == ShopType.giftShop,
                            selectedColor: AppColors.primaryLight,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedShopType = ShopType.giftShop);
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Shop Address
                      const Text('Shop Address / Location *',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _shopAddressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g. 100ft Road, Near Metro Pillar, Indiranagar',
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        validator: (val) {
                          if (_isVendorRole && (val == null || val.trim().isEmpty)) {
                            return 'Please enter your stall location address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Note: New vendor accounts will undergo Admin verification before live order bidding is activated.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (authState.errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  authState.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],

              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: authState.isLoading ? null : _handleSubmit,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Complete Profile & Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withOpacity(0.4) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              activeColor: AppColors.primary,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}

