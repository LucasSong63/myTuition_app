// lib/features/payments/presentation/widgets/other_method_form.dart

import 'package:flutter/material.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/payments/domain/entities/payment_info.dart';

class OtherMethodForm extends StatefulWidget {
  final OtherPaymentMethod? method;
  final Function(OtherPaymentMethod) onSave;

  const OtherMethodForm({
    Key? key,
    this.method,
    required this.onSave,
  }) : super(key: key);

  @override
  State<OtherMethodForm> createState() => _OtherMethodFormState();
}

class _OtherMethodFormState extends State<OtherMethodForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  bool _isActive = true;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing values if editing
    if (widget.method != null) {
      _nameController.text = widget.method!.name;
      _detailsController.text = widget.method!.details;
      _isActive = widget.method!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.method == null ? 'Add Payment Method' : 'Edit Payment Method'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Method name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Payment Method Name',
                  hintText: 'e.g., Cash, Money Order, PayPal',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the payment method name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Details field
              TextFormField(
                controller: _detailsController,
                decoration: const InputDecoration(
                  labelText: 'Details',
                  hintText: 'Enter payment method details and instructions',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter payment method details';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Is active switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    activeColor: AppColors.success,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final method = OtherPaymentMethod(
                id: widget.method?.id ?? '',
                name: _nameController.text,
                details: _detailsController.text,
                isActive: _isActive,
              );

              widget.onSave(method);
              Navigator.pop(context);
            }
          },
          child: Text(widget.method == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
