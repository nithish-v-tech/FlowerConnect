import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/state/auth_state_provider.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleGetOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final authNotifier = ref.read(authStateProvider.notifier);
    final success = await authNotifier.sendOtp(phone);

    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OtpVerificationScreen()),
      );
    }
  }

  void _demoQuickLogin(String phone) {
    ref.read(authStateProvider.notifier).quickLogin(phone);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Brand Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFFBE185D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_florist,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'FlowerConnect',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hyperlocal Florals, Bouquets & Gifts',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Login Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mobile Number Login',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'We will send a 6-digit OTP verification code to log in to your account.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 18),

                      // Phone Input Field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            child: const Text(
                              '+91',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          hintText: 'Enter 10-digit mobile number',
                          hintStyle: const TextStyle(
                              color: AppColors.textMuted, fontSize: 14),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter mobile number';
                          }
                          if (val.trim().length != 10) {
                            return 'Mobile number must be exactly 10 digits';
                          }
                          return null;
                        },
                      ),

                      if (authState.errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          authState.errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Get OTP Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed:
                              authState.isLoading ? null : _handleGetOtp,
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
                                  'Get OTP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Demo Testing Portals Header
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR TEST ROLE PORTALS INSTANTLY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),

              const SizedBox(height: 16),

              // Demo Role Cards
              _demoRoleTile(
                title: 'Customer Portal',
                subtitle: 'Pooja Hegde • +91 98765 43210',
                roleBadge: 'CUSTOMER',
                roleColor: AppColors.primary,
                icon: Icons.shopping_bag_outlined,
                onPhoneTap: () => _phoneController.text = '9876543210',
                onQuickLogin: () => _demoQuickLogin('+919876543210'),
              ),

              const SizedBox(height: 10),

              _demoRoleTile(
                title: 'Vendor Portal (Approved)',
                subtitle: 'Sri Lakshmi Stall • +91 98450 12345',
                roleBadge: 'VENDOR',
                roleColor: const Color(0xFFE11D48),
                icon: Icons.storefront_outlined,
                onPhoneTap: () => _phoneController.text = '9845012345',
                onQuickLogin: () => _demoQuickLogin('+919845012345'),
              ),

              const SizedBox(height: 10),

              _demoRoleTile(
                title: 'Vendor Portal (Pending Review)',
                subtitle: 'Sunshine Florist • +91 99999 88888',
                roleBadge: 'PENDING',
                roleColor: const Color(0xFFD97706),
                icon: Icons.hourglass_top_outlined,
                onPhoneTap: () => _phoneController.text = '9999988888',
                onQuickLogin: () => _demoQuickLogin('+919999988888'),
              ),

              const SizedBox(height: 10),

              _demoRoleTile(
                title: 'Super Admin Portal',
                subtitle: 'Super Admin • +91 90000 00001',
                roleBadge: 'ADMIN',
                roleColor: const Color(0xFF059669),
                icon: Icons.admin_panel_settings_outlined,
                onPhoneTap: () => _phoneController.text = '9000000001',
                onQuickLogin: () => _demoQuickLogin('+919000000001'),
              ),

              const SizedBox(height: 10),

              _demoRoleTile(
                title: 'Delivery Partner Portal',
                subtitle: 'Ramesh Gowda • +91 94480 33211',
                roleBadge: 'DELIVERY',
                roleColor: const Color(0xFF0284C7),
                icon: Icons.delivery_dining_outlined,
                onPhoneTap: () => _phoneController.text = '9448033211',
                onQuickLogin: () => _demoQuickLogin('+919448033211'),
              ),

              const SizedBox(height: 28),

              // Disclaimer
              const Center(
                child: Text(
                  'By continuing, you agree to FlowerConnect Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _demoRoleTile({
    required String title,
    required String subtitle,
    required String roleBadge,
    required Color roleColor,
    required IconData icon,
    required VoidCallback onPhoneTap,
    required VoidCallback onQuickLogin,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: roleColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onPhoneTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          roleBadge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
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
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(50, 30),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
            onPressed: onQuickLogin,
            child: const Text(
              'Login',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

