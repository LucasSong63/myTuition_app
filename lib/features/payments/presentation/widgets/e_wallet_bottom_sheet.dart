// lib/features/payments/presentation/widgets/e_wallet_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/payments/domain/entities/payment_info.dart';
import 'package:mytuition/features/payments/presentation/bloc/payment_info_bloc.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class EWalletBottomSheet {
  static Future<void> show({
    required BuildContext context,
    EWallet? wallet,
  }) async {
    // Get the existing bloc from the parent context
    final parentBloc = context.read<PaymentInfoBloc>();

    // Define the page content builder function
    WoltModalSheetPage pageBuilder(BuildContext context) {
      return WoltModalSheetPage(
        hasSabGradient: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        topBarTitle: Text(
          wallet == null ? 'Add E-Wallet' : 'Edit E-Wallet',
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
                  child: _EWalletForm(
                    wallet: wallet,
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

class _EWalletForm extends StatefulWidget {
  final EWallet? wallet;

  const _EWalletForm({
    this.wallet,
  });

  @override
  State<_EWalletForm> createState() => _EWalletFormState();
}

class _EWalletFormState extends State<_EWalletForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isActive = true;

  // List of common Malaysian e-wallets for suggestions
  final List<String> _eWalletTypes = [
    'Touch \'n Go eWallet',
    'Boost',
    'GrabPay',
    'MAE',
    'BigPay',
    'ShopeePay',
    'Alipay',
    'WeChat Pay'
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing values if editing
    if (widget.wallet != null) {
      _typeController.text = widget.wallet!.type;
      _numberController.text = widget.wallet!.number;
      _nameController.text = widget.wallet!.name;
      _isActive = widget.wallet!.isActive;
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    _numberController.dispose();
    _nameController.dispose();
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
                // E-wallet type field with autocomplete
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _eWalletTypes;
                    }
                    return _eWalletTypes.where((type) => type
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    _typeController.text = selection;
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    // If editing, initialize controller with existing value
                    if (widget.wallet != null && controller.text.isEmpty) {
                      controller.text = widget.wallet!.type;
                    }

                    // Store reference to this controller
                    _typeController.text = controller.text;

                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: (value) => _typeController.text = value,
                      decoration: const InputDecoration(
                        labelText: 'E-Wallet Service',
                        hintText: 'e.g., Touch \'n Go eWallet, Boost',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the e-wallet service name';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // E-wallet number/ID field
                TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number/ID',
                    hintText: 'Enter the phone number or ID linked to e-wallet',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the phone number or ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Account holder name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    hintText: 'Enter the account holder name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the account name';
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
                      onPressed: isLoading ? null : _saveWallet,
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
                              widget.wallet == null
                                  ? 'Add E-Wallet'
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

  void _saveWallet() {
    if (_formKey.currentState!.validate()) {
      final paymentInfoBloc = context.read<PaymentInfoBloc>();

      final wallet = EWallet(
        id: widget.wallet?.id ?? '',
        type: _typeController.text,
        number: _numberController.text,
        name: _nameController.text,
        isActive: _isActive,
      );

      if (widget.wallet == null) {
        paymentInfoBloc.add(AddEWalletEvent(eWallet: wallet));
      } else {
        paymentInfoBloc.add(UpdateEWalletEvent(eWallet: wallet));
      }
    }
  }
}
