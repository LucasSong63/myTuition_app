// lib/features/payments/presentation/widgets/other_method_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/payments/domain/entities/payment_info.dart';
import 'package:mytuition/features/payments/presentation/bloc/payment_info_bloc.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class OtherMethodBottomSheet {
  static Future<void> show({
    required BuildContext context,
    OtherPaymentMethod? method,
  }) async {
    // Get the existing bloc from the parent context
    final parentBloc = context.read<PaymentInfoBloc>();

    // Define the page content builder function
    WoltModalSheetPage pageBuilder(BuildContext context) {
      return WoltModalSheetPage(
        hasSabGradient: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        topBarTitle: Text(
          method == null ? 'Add Payment Method' : 'Edit Payment Method',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        isTopBarLayerAlwaysVisible: true,
        trailingNavBarWidget: IconButton(
          padding: const EdgeInsets.all(16),
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600, // Limit width on larger screens
                ),
                // Use BlocProvider.value to share the existing bloc
                child: BlocProvider.value(
                  value: parentBloc,
                  child: _OtherMethodForm(
                    method: method,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    await WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [pageBuilder(context)],
      modalTypeBuilder: (context) => WoltModalType.bottomSheet(),
      onModalDismissedWithBarrierTap: () => Navigator.of(context).pop(),
    );
  }
}

class _OtherMethodForm extends StatefulWidget {
  final OtherPaymentMethod? method;

  const _OtherMethodForm({
    this.method,
  });

  @override
  State<_OtherMethodForm> createState() => _OtherMethodFormState();
}

class _OtherMethodFormState extends State<_OtherMethodForm> {
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
    return BlocListener<PaymentInfoBloc, PaymentInfoState>(
      listener: (context, state) {
        if (state is PaymentInfoSaved) {
          // Close the modal when operation is successful
          Navigator.of(context).pop();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 24),

                // Save button
                BlocBuilder<PaymentInfoBloc, PaymentInfoState>(
                  builder: (context, state) {
                    final isLoading = state is PaymentInfoLoading;

                    return ElevatedButton(
                      onPressed: isLoading ? null : _saveMethod,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.method == null
                                  ? 'Add Method'
                                  : 'Save Changes',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveMethod() {
    if (_formKey.currentState!.validate()) {
      final paymentInfoBloc = context.read<PaymentInfoBloc>();

      final method = OtherPaymentMethod(
        id: widget.method?.id ?? '',
        name: _nameController.text,
        details: _detailsController.text,
        isActive: _isActive,
      );

      if (widget.method == null) {
        paymentInfoBloc.add(AddOtherMethodEvent(method: method));
      } else {
        paymentInfoBloc.add(UpdateOtherMethodEvent(method: method));
      }
    }
  }
}
