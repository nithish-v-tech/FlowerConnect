import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/rfq_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/state/rfq_provider.dart';
import '../../core/state/app_state_provider.dart';

class SubmitQuotationDialog extends ConsumerStatefulWidget {
  final RFQModel rfq;

  const SubmitQuotationDialog({super.key, required this.rfq});

  static void show(BuildContext context, RFQModel rfq) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubmitQuotationDialog(rfq: rfq),
    );
  }

  @override
  ConsumerState<SubmitQuotationDialog> createState() =>
      _SubmitQuotationDialogState();
}

class _SubmitQuotationDialogState extends ConsumerState<SubmitQuotationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late final TextEditingController _deliveryFeeController;
  late final TextEditingController _prepTimeController;
  late final TextEditingController _notesController;
  late final TextEditingController _freshnessController;

  @override
  void initState() {
    super.initState();
    final defaultPrice = widget.rfq.targetBudget != null
        ? (widget.rfq.targetBudget! * 0.95).round().toString()
        : '1200';
    _priceController = TextEditingController(text: defaultPrice);
    _deliveryFeeController = TextEditingController(
      text: widget.rfq.deliveryPreference == DeliveryPreference.homeDelivery
          ? '35'
          : '0',
    );
    _prepTimeController = TextEditingController(text: '20');
    _notesController = TextEditingController(
      text:
          'Fresh morning harvest stems, bundled with water retention sponge.',
    );
    _freshnessController = TextEditingController(
      text: 'Guaranteed 5-day fresh blossoms with flower booster nutrient.',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _deliveryFeeController.dispose();
    _prepTimeController.dispose();
    _notesController.dispose();
    _freshnessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final user = appState.currentUser;
    final shop = appState.shops.firstWhere(
      (s) => s.id == user.shopId,
      orElse: () => appState.shops.first,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Submit Merchant Quotation',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    shop.name,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Bidding for: ${widget.rfq.title} (${widget.rfq.quantityDescription})',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const Divider(height: 20),

              // Quoted Price & Delivery Fee
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Offer Price (₹)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          decoration:
                              const InputDecoration(hintText: 'e.g. 1400'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delivery Fee (₹)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _deliveryFeeController,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          decoration:
                              const InputDecoration(hintText: 'e.g. 40'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Prep Time
              const Text('Preparation Time (Minutes)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _prepTimeController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                decoration: const InputDecoration(
                    hintText: 'Time needed to arrange flowers'),
              ),

              const SizedBox(height: 14),

              // Freshness Guarantee
              const Text('Freshness Guarantee',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _freshnessController,
                decoration: const InputDecoration(
                    hintText: 'e.g. 100% morning fresh cut with nutrient pack'),
              ),

              const SizedBox(height: 14),

              // Special Merchant Notes
              const Text('Notes to Customer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                    hintText: 'Special stem details, packaging etc.'),
              ),

              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final price = double.parse(_priceController.text.trim());
                    final delivery =
                        double.parse(_deliveryFeeController.text.trim());
                    final prep = int.parse(_prepTimeController.text.trim());

                    ref.read(rfqProvider.notifier).submitQuotation(
                          rfqId: widget.rfq.id,
                          merchantId: user.id,
                          shopId: shop.id,
                          shopName: shop.name,
                          merchantPhone: shop.contactPhone,
                          merchantRating: shop.rating,
                          distanceKm: shop.distanceKm,
                          quotedPrice: price,
                          deliveryFee: delivery,
                          prepTimeMinutes: prep,
                          notes: _notesController.text.trim(),
                          freshnessGuarantee: _freshnessController.text.trim(),
                        );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Quotation of ₹${price.toStringAsFixed(0)} submitted to customer!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Send Quotation to Customer',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

