import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/custom_bouquet_model.dart';
import '../../core/models/product_model.dart';
import '../../core/constants/demo_data.dart';
import '../../core/state/cart_provider.dart';
import '../customer/cart_screen.dart';
import '../quotation/create_rfq_screen.dart';

class CustomBouquetBuilderScreen extends ConsumerStatefulWidget {
  const CustomBouquetBuilderScreen({super.key});

  @override
  ConsumerState<CustomBouquetBuilderScreen> createState() =>
      _CustomBouquetBuilderScreenState();
}

class _CustomBouquetBuilderScreenState
    extends ConsumerState<CustomBouquetBuilderScreen> {
  late BouquetBaseOption _selectedBase;
  late RibbonOption _selectedRibbon;
  final Map<FlowerStemOption, int> _stemCounts = {};
  final List<BouquetAddonOption> _selectedAddons = [];
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedBase = DemoData.bouquetBases[0];
    _selectedRibbon = DemoData.ribbons[1]; // Crimson satin
    // Default initial flowers
    _stemCounts[DemoData.flowerStems[0]] = 12; // 12 red roses
    _stemCounts[DemoData.flowerStems[2]] = 2; // 2 white lilies
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  int get _totalStems => _stemCounts.values.fold(0, (s, c) => s + c);

  double get _stemsCost {
    double total = 0.0;
    _stemCounts.forEach((stem, count) {
      total += stem.pricePerStem * count;
    });
    return total;
  }

  double get _addonsCost =>
      _selectedAddons.fold(0.0, (sum, addon) => sum + addon.price);

  double get _totalPrice =>
      _selectedBase.price + _selectedRibbon.price + _stemsCost + _addonsCost;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Custom Bouquet Studio',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _stemCounts.clear();
                _stemCounts[DemoData.flowerStems[0]] = 12;
                _selectedAddons.clear();
                _messageController.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Visual Bouquet Dynamic Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(_selectedBase.iconEmoji,
                        style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedBase.name} • $_totalStems Stems',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ribbon: ${_selectedRibbon.name} • ${_selectedAddons.length} Add-ons',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Estimate',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textSecondary)),
                    Text(
                      '₹${_totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable Studio Steps
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // STEP 1: Select Base
                _buildSectionTitle('1. Choose Base & Wrapping Style',
                    'Select how your arrangement is presented'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: DemoData.bouquetBases.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final base = DemoData.bouquetBases[index];
                      final isSelected = _selectedBase.id == base.id;
                      return InkWell(
                        onTap: () => setState(() => _selectedBase = base),
                        child: Container(
                          width: 130,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryLight
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.divider,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(base.iconEmoji,
                                  style: const TextStyle(fontSize: 24)),
                              const Spacer(),
                              Text(
                                base.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '+₹${base.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 22),

                // STEP 2: Pick Stems & Flower Count
                _buildSectionTitle('2. Select Fresh Stems & Quantities',
                    'Mix and match freshly cut flowers'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: DemoData.flowerStems.map((stem) {
                      final count = _stemCounts[stem] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Text(stem.emoji,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stem.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                  Text(
                                    '₹${stem.pricePerStem.toStringAsFixed(0)} / stem',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            // Counter
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    constraints: const BoxConstraints(
                                        minWidth: 28, minHeight: 28),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.remove, size: 14),
                                    onPressed: count > 0
                                        ? () {
                                            setState(() {
                                              if (count == 1) {
                                                _stemCounts.remove(stem);
                                              } else {
                                                _stemCounts[stem] = count - 1;
                                              }
                                            });
                                          }
                                        : null,
                                  ),
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '$count',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                                  IconButton(
                                    constraints: const BoxConstraints(
                                        minWidth: 28, minHeight: 28),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.add, size: 14),
                                    onPressed: () {
                                      setState(() {
                                        _stemCounts[stem] = count + 1;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 50,
                              child: Text(
                                '₹${(count * stem.pricePerStem).toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 22),

                // STEP 3: Ribbon Choice
                _buildSectionTitle(
                    '3. Ribbon & Embellishment', 'Wrap with luxury silk/satin'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: DemoData.ribbons.map((ribbon) {
                    final isSelected = _selectedRibbon.id == ribbon.id;
                    return InkWell(
                      onTap: () => setState(() => _selectedRibbon = ribbon),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎗️', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              '${ribbon.name} (+₹${ribbon.price.toStringAsFixed(0)})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 22),

                // STEP 4: Add-ons & Gifts
                _buildSectionTitle('4. Add-on Chocolates & Gifts',
                    'Elevate with chocolates, teddy & card'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: DemoData.addons.map((addon) {
                      final isAdded = _selectedAddons
                          .any((item) => item.id == addon.id);
                      return CheckboxListTile(
                        value: isAdded,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedAddons.add(addon);
                            } else {
                              _selectedAddons
                                  .removeWhere((item) => item.id == addon.id);
                            }
                          });
                        },
                        secondary: Text(addon.emoji,
                            style: const TextStyle(fontSize: 22)),
                        title: Text(addon.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(
                            '${addon.description} (+₹${addon.price.toStringAsFixed(0)})',
                            style: const TextStyle(fontSize: 11)),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 22),

                // STEP 5: Handwritten Note
                _buildSectionTitle('5. Handwritten Card Message',
                    'Printed on luxury textured card paper'),
                const SizedBox(height: 10),
                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Dearest Mom, Happy 50th Birthday! Wishing you vibrant health and joy. Love, Sneha.',
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Request Quotation for this custom bouquet
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _totalStems == 0
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateRFQScreen(
                                    initialTitle:
                                        'Custom Arrangement: $_totalStems Stems in ${_selectedBase.name}',
                                    initialFlowerType:
                                        'Custom Bouquet ($_totalStems stems)',
                                    initialQty:
                                        '${_selectedBase.name} with $_totalStems mixed stems & ${_selectedRibbon.name} ribbon',
                                    initialBudget: _totalPrice,
                                  ),
                                ),
                              );
                            },
                      child: const Text('Get RFQ Quotes',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Direct Add to Cart
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _totalStems == 0
                          ? null
                          : () {
                              final customProduct = ProductModel(
                                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                                shopId: 'shop_002',
                                shopName: 'Petals & Blooms Studio',
                                name:
                                    'Custom Bouquet (${_totalStems} Stems in ${_selectedBase.name})',
                                description:
                                    'Custom hand-tied arrangement: $_totalStems stems, ${_selectedRibbon.name} ribbon, ${_selectedAddons.length} add-ons.',
                                category: ProductCategory.customBouquet,
                                price: _totalPrice,
                                unit: 'Custom Design',
                                imageUrl:
                                    'https://images.unsplash.com/photo-1526047932273-341f2a7631f9?auto=format&fit=crop&w=600&q=80',
                              );

                              ref
                                  .read(cartProvider.notifier)
                                  .addToCart(customProduct);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Custom Bouquet added to your cart!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CartScreen()),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(
                        'Buy Now ₹${_totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
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
    );
  }
}

