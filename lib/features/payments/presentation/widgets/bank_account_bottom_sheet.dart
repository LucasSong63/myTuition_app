// lib/features/payments/presentation/widgets/bank_account_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        isTopBarLayerAlwaysVisible: true,
        trailingNavBarWidget: IconButton(
          padding: EdgeInsets.all(4.w),
          icon: Icon(Icons.close, size: 6.w),
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
        padding: EdgeInsets.all(4.w),
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
                  style: TextStyle(fontSize: 14.sp),
                  decoration: InputDecoration(
                    labelText: 'Bank Name',
                    labelStyle: TextStyle(fontSize: 14.sp),
                    hintText: 'e.g., Maybank, CIMB, Public Bank',
                    hintStyle: TextStyle(fontSize: 13.sp),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 3.5.w,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the bank name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 4.w),

                // Account number field
                TextFormField(
                  controller: _accountNumberController,
                  style: TextStyle(fontSize: 14.sp),
                  decoration: InputDecoration(
                    labelText: 'Account Number',
                    labelStyle: TextStyle(fontSize: 14.sp),
                    hintText: 'Enter the bank account number',
                    hintStyle: TextStyle(fontSize: 13.sp),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 3.5.w,
                    ),
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
                SizedBox(height: 4.w),

                // Account holder field
                TextFormField(
                  controller: _accountHolderController,
                  style: TextStyle(fontSize: 14.sp),
                  decoration: InputDecoration(
                    labelText: 'Account Holder',
                    labelStyle: TextStyle(fontSize: 14.sp),
                    hintText: 'Enter the account holder name',
                    hintStyle: TextStyle(fontSize: 13.sp),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 3.5.w,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the account holder name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 4.w),

                // Is active switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 16.sp,
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
                SizedBox(height: 6.w),

                // Save button
                BlocBuilder<PaymentInfoBloc, PaymentInfoState>(
                  builder: (context, state) {
                    final isLoading = state is PaymentInfoLoading;

                    return ElevatedButton(
                      onPressed: isLoading ? null : _saveAccount,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 3.5.w),
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2.w),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 6.w,
                              height: 6.w,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.account == null
                                  ? 'Add Account'
                                  : 'Save Changes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
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
