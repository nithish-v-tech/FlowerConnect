import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/rfq_model.dart';
import '../../core/state/rfq_provider.dart';
import '../../core/state/app_state_provider.dart';
import 'quotation_comparison_screen.dart';

class CreateRFQScreen extends ConsumerStatefulWidget {
  final String? initialTitle;
  final String? initialFlowerType;
  final String? initialQty;
  final double? initialBudget;
  final String? targetShopName;

  const CreateRFQScreen({
    super.key,
    this.initialTitle,
    this.initialFlowerType,
    this.initialQty,
    this.initialBudget,
    this.targetShopName,
  });

  @override
  ConsumerState<CreateRFQScreen> createState() => _CreateRFQScreenState();
}

class _CreateRFQScreenState extends ConsumerState<CreateRFQScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _flowerTypeController;
  late final TextEditingController _quantityController;
  late final TextEditingController _budgetController;
  late final TextEditingController _occasionController;
  late final TextEditingController _addressController;

  DeliveryPreference _preference = DeliveryPreference.homeDelivery;
  int _needByHours = 3;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialTitle ?? '50 Red Roses + 5 White Lilies for Wedding Anniversary',
    );
    _flowerTypeController = TextEditingController(
      text: widget.initialFlowerType ?? 'Fresh Dutch Red Roses & Lilies',
    );
    _quantityController = TextEditingController(
      text: widget.initialQty ?? '50 long-stem roses, 5 lilies with foliage',
    );
    _budgetController = TextEditingController(
      text: widget.initialBudget != null ? widget.initialBudget!.toStringAsFixed(0) : '2000',
    );
    _occasionController = TextEditingController(text: 'Wedding Anniversary');
    _addressController = TextEditingController(
      text: 'Flat 402, Oakwood Heights, 12th Main Indiranagar, Bengaluru',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _flowerTypeController.dispose();
    _quantityController.dispose();
    _budgetController.dispose();
    _occasionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post Requirement (RFQ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Broadcast Explainer Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.amberLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sensors, color: AppColors.amber, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hyperlocal Smart Broadcast',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.targetShopName != null
                              ? 'Requesting quote from ${widget.targetShopName} and nearby matched shops within 5km.'
                              : 'Your request will be broadcast to licensed florists & roadside stalls within 5km radius.',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Title
              const Text('Requirement Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                validator: (val) => val == null || val.isEmpty ? 'Title required' : null,
                decoration: const InputDecoration(hintText: 'e.g. 50 Roses for Birthday Surprise'),
              ),

              const SizedBox(height: 14),

              // Flower Type
              const Text('Flower / Arrangement Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _flowerTypeController,
                validator: (val) => val == null || val.isEmpty ? 'Flower type required' : null,
                decoration: const InputDecoration(hintText: 'e.g. Jasmine (Malli), Dutch Rose, Marigold'),
              ),

              const SizedBox(height: 14),

              // Quantity Description
              const Text('Quantity & Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _quantityController,
                validator: (val) => val == null || val.isEmpty ? 'Quantity required' : null,
                decoration: const InputDecoration(hintText: 'e.g. 2 kg Jasmine string or 30 stems'),
              ),

              const SizedBox(height: 14),

              // Occasion & Target Budget Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Occasion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _occasionController,
                          decoration: const InputDecoration(hintText: 'e.g. Pooja / Birthday'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Budget Target (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'e.g. 1500'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Preference: Home Delivery vs Self-Pickup
              const Text('Delivery Preference', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delivery_dining, size: 16),
                          SizedBox(width: 6),
                          Text('Home Delivery'),
                        ],
                      ),
                      selected: _preference == DeliveryPreference.homeDelivery,
                      onSelected: (val) {
                        if (val) setState(() => _preference = DeliveryPreference.homeDelivery);
                      },
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _preference == DeliveryPreference.homeDelivery
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront, size: 16),
                          SizedBox(width: 6),
                          Text('Self-Pickup'),
                        ],
                      ),
                      selected: _preference == DeliveryPreference.selfPickup,
                      onSelected: (val) {
                        if (val) setState(() => _preference = DeliveryPreference.selfPickup);
                      },
                      selectedColor: AppColors.accentLight,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _preference == DeliveryPreference.selfPickup
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Address
              const Text('Your Location / Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressController,
                validator: (val) => val == null || val.isEmpty ? 'Address required' : null,
                decoration: const InputDecoration(hintText: 'Enter complete street address'),
              ),

              const SizedBox(height: 16),

              // Need-By Window
              const Text('Needed Within', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [1, 2, 3, 6, 24].map((hours) {
                  final isSelected = _needByHours == hours;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(hours == 24 ? 'Tomorrow' : '$hours hrs'),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _needByHours = hours);
                      },
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // Submit & Broadcast Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final budget = double.tryParse(_budgetController.text.trim());
                    final rfq = ref.read(rfqProvider.notifier).createRFQ(
                          customerId: appState.currentUser.id,
                          customerName: appState.currentUser.name,
                          title: _titleController.text.trim(),
                          flowerType: _flowerTypeController.text.trim(),
                          quantityDescription: _quantityController.text.trim(),
                          occasion: _occasionController.text.trim(),
                          deliveryPreference: _preference,
                          deliveryAddress: _addressController.text.trim(),
                          targetBudget: budget,
                          needBy: DateTime.now().add(Duration(hours: _needByHours)),
                        );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('RFQ broadcasted to 4 nearby shops! Awaiting competitive bids...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuotationComparisonScreen(rfqId: rfq.id),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send),
                    SizedBox(width: 8),
                    Text('Broadcast RFQ & Compare Quotes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

