// lib/features/payments/presentation/widgets/bank_account_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/payments/domain/entities/payment_info.dart';
import 'package:mytuition/features/payments/presentation/bloc/payment_info_bloc.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class BankAccountBottomSheet {
  static Future<void> show({
    required BuildContext context,
    BankAccount? account,
  }) async {
    // Get the existing bloc from the parent context
    final parentBloc = context.read<PaymentInfoBloc>();

    // Define the page content builder function
    WoltModalSheetPage pageBuilder(BuildContext context) {
      return WoltModalSheetPage(
        hasSabGradient: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        topBarTitle: Text(
          account == null ? 'Add Bank Account' : 'Edit Bank Account',
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
                  child: _BankAccountForm(
                    account: account,
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

class _BankAccountForm extends StatefulWidget {
  final BankAccount? account;

  const _BankAccountForm({
    this.account,
  });

  @override
  State<_BankAccountForm> createState() => _BankAccountFormState();
}

class _BankAccountFormState extends State<_BankAccountForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();

  bool _isActive = true;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing values if editing
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _accountNumberController.text = widget.account!.accountNumber;
      _accountHolderController.text = widget.account!.accountHolder;
      _isActive = widget.account!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
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
                // Bank name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    hintText: 'e.g., Maybank, CIMB, Public Bank',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the bank name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Account number field
                TextFormField(
                  controller: _accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    hintText: 'Enter the bank account number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the account number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Account holder field
                TextFormField(
                  controller: _accountHolderController,
                  decoration: const InputDecoration(
                    labelText: 'Account Holder',
                    hintText: 'Enter the account holder name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the account holder name';
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
                      onPressed: isLoading ? null : _saveAccount,
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
                              widget.account == null
                                  ? 'Add Account'
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

  void _saveAccount() {
    if (_formKey.currentState!.validate()) {
      final paymentInfoBloc = context.read<PaymentInfoBloc>();

      final account = BankAccount(
        id: widget.account?.id ?? '',
        name: _nameController.text,
        accountNumber: _accountNumberController.text,
        accountHolder: _accountHolderController.text,
        isActive: _isActive,
      );

      if (widget.account == null) {
        paymentInfoBloc.add(AddBankAccountEvent(bankAccount: account));
      } else {
        paymentInfoBloc.add(UpdateBankAccountEvent(bankAccount: account));
      }
    }
  }
}
