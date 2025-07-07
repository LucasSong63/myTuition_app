// lib/features/payments/presentation/pages/payment_info_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/payments/domain/entities/payment_info.dart';
import 'package:mytuition/features/payments/presentation/widgets/bank_account_bottom_sheet.dart';
import 'package:mytuition/features/payments/presentation/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:mytuition/features/payments/presentation/widgets/e_wallet_bottom_sheet.dart';
import 'package:mytuition/features/payments/presentation/widgets/other_method_bottom_sheet.dart';
import '../bloc/payment_info_bloc.dart';

class PaymentInfoPage extends StatefulWidget {
  const PaymentInfoPage({Key? key}) : super(key: key);

  @override
  State<PaymentInfoPage> createState() => _PaymentInfoPageState();
}

class _PaymentInfoPageState extends State<PaymentInfoPage> {
  final _additionalInfoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    // Load payment info when widget is initialized
    context.read<PaymentInfoBloc>().add(LoadPaymentInfoEvent());
  }

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }

  void _populateAdditionalInfo(PaymentInfo paymentInfo) {
    _additionalInfoController.text = paymentInfo.additionalInfo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Information',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        actions: [
          BlocBuilder<PaymentInfoBloc, PaymentInfoState>(
            builder: (context, state) {
              if (state is PaymentInfoLoaded) {
                return IconButton(
                  icon: Icon(_isEditMode ? Icons.close : Icons.edit, size: 6.w),
                  onPressed: () {
                    setState(() {
                      _isEditMode = !_isEditMode;
                      if (!_isEditMode) {
                        // Reset form when canceling
                        _populateAdditionalInfo(state.paymentInfo);
                      }
                    });
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<PaymentInfoBloc, PaymentInfoState>(
        listener: (context, state) {
          if (state is PaymentInfoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
                backgroundColor: AppColors.error,
              ),
            );
          }

          if (state is PaymentInfoSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
                backgroundColor: AppColors.success,
              ),
            );
          }

          if (state is PaymentInfoLoaded && !_isEditMode) {
            _populateAdditionalInfo(state.paymentInfo);
          }
        },
        builder: (context, state) {
          if (state is PaymentInfoLoading && !(state is PaymentInfoLoaded)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PaymentInfoLoaded) {
            final paymentInfo = state.paymentInfo;

            return Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(4.w),
                children: [
                  // Instructions card
                  _buildInstructionsCard(),

                  SizedBox(height: 6.w),

                  // Bank Accounts Section
                  _buildSectionHeader('Bank Account Details',
                      onAdd: _isEditMode
                          ? () => _showAddBankAccountBottomSheet(context)
                          : null),

                  if (paymentInfo.bankAccounts.isEmpty)
                    _buildEmptyState('No bank accounts added yet',
                        'Add your bank account details')
                  else
                    _buildBankAccountsList(paymentInfo.bankAccounts),

                  SizedBox(height: 6.w),

                  // E-Wallet Section
                  _buildSectionHeader('E-Wallet Details',
                      onAdd: _isEditMode
                          ? () => _showAddEWalletBottomSheet(context)
                          : null),

                  if (paymentInfo.eWallets.isEmpty)
                    _buildEmptyState(
                        'No e-wallets added yet', 'Add your e-wallet details')
                  else
                    _buildEWalletsList(paymentInfo.eWallets),

                  SizedBox(height: 6.w),

                  // Other Payment Methods Section
                  _buildSectionHeader('Other Payment Methods',
                      onAdd: _isEditMode
                          ? () => _showAddOtherMethodBottomSheet(context)
                          : null),

                  if (paymentInfo.otherMethods.isEmpty)
                    _buildEmptyState('No other payment methods added',
                        'Add other payment methods')
                  else
                    _buildOtherMethodsList(paymentInfo.otherMethods),

                  SizedBox(height: 6.w),

                  // Additional Information
                  _buildSectionHeader('Additional Information'),
                  _buildAdditionalInfoField(_isEditMode),

                  SizedBox(height: 6.w),

                  // Save button
                  if (_isEditMode)
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final updatedInfo = paymentInfo.copyWith(
                            additionalInfo: _additionalInfoController.text,
                          );

                          context
                              .read<PaymentInfoBloc>()
                              .add(SavePaymentInfoEvent(
                                paymentInfo: updatedInfo,
                              ));

                          setState(() {
                            _isEditMode = false;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: EdgeInsets.symmetric(vertical: 3.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2.w),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                    ),

                  SizedBox(height: 8.w),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Failed to load payment information',
                    style: TextStyle(fontSize: 16.sp)),
                SizedBox(height: 4.w),
                ElevatedButton(
                  onPressed: () {
                    context.read<PaymentInfoBloc>().add(LoadPaymentInfoEvent());
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.w),
                  ),
                  child: Text('Retry', style: TextStyle(fontSize: 14.sp)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      margin: EdgeInsets.only(bottom: 2.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryBlue,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Payment Information',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.w),
            Text(
              'This page allows you to manage the payment information that will be displayed to students. '
              'Students will see these details when viewing their payment records, helping them to make payments correctly.',
              style: TextStyle(
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 2.w),
            Text(
              'Tap the edit button in the top right corner to add or modify payment methods.',
              style: TextStyle(
                fontSize: 14.sp,
                fontStyle: FontStyle.italic,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAdd}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onAdd != null)
            IconButton(
              icon: Icon(Icons.add_circle, color: AppColors.success, size: 7.w),
              onPressed: onAdd,
              tooltip: 'Add New',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 12.w,
              color: AppColors.textLight,
            ),
            SizedBox(height: 4.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.w),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textMedium,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankAccountsList(List<BankAccount> accounts) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return _buildBankAccountItem(account);
      },
    );
  }

  Widget _buildBankAccountItem(BankAccount account) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1.w),
                      Text(
                        'Account Holder: ${account.accountHolder}',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isEditMode)
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: AppColors.primaryBlue, size: 6.w),
                        onPressed: () =>
                            _showEditBankAccountBottomSheet(context, account),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: AppColors.error, size: 6.w),
                        onPressed: () => _showDeleteConfirmationBottomSheet(
                          context,
                          'Delete Bank Account',
                          'Are you sure you want to delete this bank account?',
                          () {
                            context.read<PaymentInfoBloc>().add(
                                  DeleteBankAccountEvent(accountId: account.id),
                                );
                          },
                        ),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
              ],
            ),
            Divider(height: 6.w),
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  size: 5.w,
                  color: AppColors.primaryBlue,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Account Number: ${account.accountNumber}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (!account.isActive)
              Padding(
                padding: EdgeInsets.only(top: 2.w),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(1.w),
                  ),
                  child: Text(
                    'Inactive',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEWalletsList(List<EWallet> wallets) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: wallets.length,
      itemBuilder: (context, index) {
        final wallet = wallets[index];
        return _buildEWalletItem(wallet);
      },
    );
  }

  Widget _buildEWalletItem(EWallet wallet) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.type,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1.w),
                      Text(
                        'Account Name: ${wallet.name}',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isEditMode)
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: AppColors.primaryBlue, size: 6.w),
                        onPressed: () =>
                            _showEditEWalletBottomSheet(context, wallet),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: AppColors.error, size: 6.w),
                        onPressed: () => _showDeleteConfirmationBottomSheet(
                          context,
                          'Delete E-Wallet',
                          'Are you sure you want to delete this e-wallet?',
                          () {
                            context.read<PaymentInfoBloc>().add(
                                  DeleteEWalletEvent(walletId: wallet.id),
                                );
                          },
                        ),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
              ],
            ),
            Divider(height: 6.w),
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 5.w,
                  color: AppColors.accentOrange,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Number/ID: ${wallet.number}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (!wallet.isActive)
              Padding(
                padding: EdgeInsets.only(top: 2.w),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(1.w),
                  ),
                  child: Text(
                    'Inactive',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherMethodsList(List<OtherPaymentMethod> methods) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: methods.length,
      itemBuilder: (context, index) {
        final method = methods[index];
        return _buildOtherMethodItem(method);
      },
    );
  }

  Widget _buildOtherMethodItem(OtherPaymentMethod method) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    method.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isEditMode)
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: AppColors.primaryBlue, size: 6.w),
                        onPressed: () =>
                            _showEditOtherMethodBottomSheet(context, method),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: AppColors.error, size: 6.w),
                        onPressed: () => _showDeleteConfirmationBottomSheet(
                          context,
                          'Delete Payment Method',
                          'Are you sure you want to delete this payment method?',
                          () {
                            context.read<PaymentInfoBloc>().add(
                                  DeleteOtherMethodEvent(methodId: method.id),
                                );
                          },
                        ),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
              ],
            ),
            Divider(height: 6.w),
            Text(
              method.details,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 14.sp,
              ),
            ),
            if (!method.isActive)
              Padding(
                padding: EdgeInsets.only(top: 2.w),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(1.w),
                  ),
                  child: Text(
                    'Inactive',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoField(bool isEditable) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: isEditable
            ? TextFormField(
                controller: _additionalInfoController,
                maxLines: 5,
                style: TextStyle(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText:
                      'Enter any additional payment instructions or information for students',
                  hintStyle: TextStyle(fontSize: 14.sp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 3.w,
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_additionalInfoController.text.isNotEmpty)
                    Text(
                      _additionalInfoController.text,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14.sp,
                      ),
                    )
                  else
                    Text(
                      'No additional information provided',
                      style: TextStyle(
                        color: AppColors.textMedium,
                        fontStyle: FontStyle.italic,
                        fontSize: 14.sp,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  // Bottom sheet methods
  void _showAddBankAccountBottomSheet(BuildContext context) {
    BankAccountBottomSheet.show(context: context);
  }

  void _showEditBankAccountBottomSheet(
      BuildContext context, BankAccount account) {
    BankAccountBottomSheet.show(context: context, account: account);
  }

  void _showAddEWalletBottomSheet(BuildContext context) {
    EWalletBottomSheet.show(context: context);
  }

  void _showEditEWalletBottomSheet(BuildContext context, EWallet wallet) {
    EWalletBottomSheet.show(context: context, wallet: wallet);
  }

  void _showAddOtherMethodBottomSheet(BuildContext context) {
    OtherMethodBottomSheet.show(context: context);
  }

  void _showEditOtherMethodBottomSheet(
      BuildContext context, OtherPaymentMethod method) {
    OtherMethodBottomSheet.show(context: context, method: method);
  }

  Future<void> _showDeleteConfirmationBottomSheet(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) async {
    final confirmed = await DeleteConfirmationBottomSheet.show(
      context: context,
      title: title,
      message: message,
    );

    if (confirmed) {
      onConfirm();
    }
  }
}
