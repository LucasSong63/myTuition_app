import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/payments/domain/entities/payment_info.dart';

class StudentPaymentInfoCard extends StatefulWidget {
  final PaymentInfo paymentInfo;
  final bool hasOutstandingPayments;
  final double totalOutstanding;

  const StudentPaymentInfoCard({
    Key? key,
    required this.paymentInfo,
    this.hasOutstandingPayments = false,
    this.totalOutstanding = 0.0,
  }) : super(key: key);

  @override
  State<StudentPaymentInfoCard> createState() => _StudentPaymentInfoCardState();
}

class _StudentPaymentInfoCardState extends State<StudentPaymentInfoCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasAnyPaymentMethod = widget.paymentInfo.bankAccounts.isNotEmpty ||
        widget.paymentInfo.eWallets.isNotEmpty ||
        widget.paymentInfo.otherMethods.isNotEmpty;

    if (!hasAnyPaymentMethod) {
      return _buildEmptyState();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic info message
            _buildInfoMessage(),

            SizedBox(height: 4.w),

            // Payment methods summary or full view
            if (_isExpanded) ...[
              _buildFullPaymentMethods(),
            ] else ...[
              _buildCompactPaymentMethods(),
            ],

            // Additional Information (if exists and expanded)
            if (_isExpanded &&
                widget.paymentInfo.additionalInfo.isNotEmpty) ...[
              SizedBox(height: 4.w),
              _buildAdditionalInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoMessage() {
    if (widget.hasOutstandingPayments) {
      return Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(2.w),
          border: Border.all(
            color: AppColors.warning.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_outlined,
              color: AppColors.warning,
              size: 5.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Outstanding Payment Reminder',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'You have RM ${widget.totalOutstanding.toStringAsFixed(2)} in outstanding payments',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: AppColors.primaryBlueLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(2.w),
          border: Border.all(
            color: AppColors.primaryBlueLight.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.primaryBlue,
              size: 5.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Use any of the payment methods below to make your payments',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCompactPaymentMethods() {
    final totalMethods = widget.paymentInfo.bankAccounts.length +
        widget.paymentInfo.eWallets.length +
        widget.paymentInfo.otherMethods.length;

    return Column(
      children: [
        // Summary row
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(3.w),
            border: Border.all(
              color: AppColors.backgroundDark.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Icon(
                  Icons.payment,
                  color: AppColors.primaryBlue,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Methods Available',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      _buildMethodsSummary(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _isExpanded = true),
                icon: Icon(
                  Icons.expand_more,
                  color: AppColors.primaryBlue,
                  size: 6.w,
                ),
                tooltip: 'View all payment methods',
              ),
            ],
          ),
        ),

        // Quick preview of first method (if available)
        if (widget.paymentInfo.bankAccounts.isNotEmpty) ...[
          SizedBox(height: 3.w),
          _buildQuickPreview(),
        ],
      ],
    );
  }

  String _buildMethodsSummary() {
    List<String> methods = [];

    if (widget.paymentInfo.bankAccounts.isNotEmpty) {
      methods.add(
          '${widget.paymentInfo.bankAccounts.length} Bank Account${widget.paymentInfo.bankAccounts.length > 1 ? 's' : ''}');
    }

    if (widget.paymentInfo.eWallets.isNotEmpty) {
      methods.add(
          '${widget.paymentInfo.eWallets.length} E-Wallet${widget.paymentInfo.eWallets.length > 1 ? 's' : ''}');
    }

    if (widget.paymentInfo.otherMethods.isNotEmpty) {
      methods.add(
          '${widget.paymentInfo.otherMethods.length} Other Method${widget.paymentInfo.otherMethods.length > 1 ? 's' : ''}');
    }

    return methods.join(' • ');
  }

  Widget _buildQuickPreview() {
    final firstBank = widget.paymentInfo.bankAccounts.first;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance,
            color: AppColors.primaryBlue,
            size: 5.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstBank.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'Account: ${_maskAccountNumber(firstBank.accountNumber)}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copyToClipboard(context, firstBank.accountNumber),
            icon: Icon(
              Icons.copy,
              color: AppColors.primaryBlue,
              size: 4.w,
            ),
            tooltip: 'Copy account number',
          ),
        ],
      ),
    );
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;

    final visiblePart = accountNumber.substring(accountNumber.length - 4);
    final maskedPart = '*' * (accountNumber.length - 4);

    return '$maskedPart$visiblePart';
  }

  Widget _buildFullPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with collapse button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Methods',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _isExpanded = false),
              icon: Icon(
                Icons.expand_less,
                color: AppColors.primaryBlue,
                size: 6.w,
              ),
              tooltip: 'Collapse',
            ),
          ],
        ),

        SizedBox(height: 2.w),

        // Bank Accounts Section
        if (widget.paymentInfo.bankAccounts.isNotEmpty) ...[
          _buildSectionHeader('🏦 Bank Accounts'),
          SizedBox(height: 3.w),
          ...widget.paymentInfo.bankAccounts
              .where((account) => account.isActive)
              .map((account) => Padding(
                    padding: EdgeInsets.only(bottom: 3.w),
                    child: _buildBankAccountItem(account, context),
                  )),
        ],

        // E-Wallets Section
        if (widget.paymentInfo.eWallets.isNotEmpty) ...[
          if (widget.paymentInfo.bankAccounts.isNotEmpty) SizedBox(height: 4.w),
          _buildSectionHeader('💳 E-Wallets'),
          SizedBox(height: 3.w),
          ...widget.paymentInfo.eWallets
              .where((wallet) => wallet.isActive)
              .map((wallet) => Padding(
                    padding: EdgeInsets.only(bottom: 3.w),
                    child: _buildEWalletItem(wallet, context),
                  )),
        ],

        // Other Payment Methods Section
        if (widget.paymentInfo.otherMethods.isNotEmpty) ...[
          if (widget.paymentInfo.bankAccounts.isNotEmpty ||
              widget.paymentInfo.eWallets.isNotEmpty)
            SizedBox(height: 4.w),
          _buildSectionHeader('💰 Other Methods'),
          SizedBox(height: 3.w),
          ...widget.paymentInfo.otherMethods
              .where((method) => method.isActive)
              .map((method) => Padding(
                    padding: EdgeInsets.only(bottom: 3.w),
                    child: _buildOtherMethodItem(method, context),
                  )),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('📋 Additional Information'),
        SizedBox(height: 3.w),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(3.w),
            border: Border.all(
              color: AppColors.backgroundDark,
            ),
          ),
          child: Text(
            widget.paymentInfo.additionalInfo,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payment_outlined,
                size: 12.w,
                color: AppColors.textLight,
              ),
            ),
            SizedBox(height: 4.w),
            Text(
              'No Payment Methods Available',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 2.w),
            Text(
              'Payment information will be available once your tutor sets up the payment methods.',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildBankAccountItem(BankAccount account, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with bank info and copy button
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: AppColors.primaryBlue,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  account.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    _copyToClipboard(context, account.accountNumber),
                icon: Icon(
                  Icons.copy,
                  color: AppColors.primaryBlue,
                  size: 5.w,
                ),
                tooltip: 'Copy account number',
              ),
            ],
          ),

          SizedBox(height: 3.w),

          // Account details
          _buildDetailItem(
              'Account Holder:', account.accountHolder, Icons.person),
          SizedBox(height: 2.w),
          _buildDetailItem(
              'Account Number:', account.accountNumber, Icons.numbers),
        ],
      ),
    );
  }

  Widget _buildEWalletItem(EWallet wallet, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: AppColors.accentOrange.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.accentOrange,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  wallet.type,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(context, wallet.number),
                icon: Icon(
                  Icons.copy,
                  color: AppColors.accentOrange,
                  size: 5.w,
                ),
                tooltip: 'Copy number/ID',
              ),
            ],
          ),

          SizedBox(height: 3.w),

          // Details
          _buildDetailItem('Account Name:', wallet.name, Icons.person),
          SizedBox(height: 2.w),
          _buildDetailItem('Number/ID:', wallet.number, Icons.phone_android),
        ],
      ),
    );
  }

  Widget _buildOtherMethodItem(
      OtherPaymentMethod method, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: AppColors.accentTeal.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Icon(
                  Icons.payment,
                  color: AppColors.accentTeal,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  method.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(context, method.details),
                icon: Icon(
                  Icons.copy,
                  color: AppColors.accentTeal,
                  size: 5.w,
                ),
                tooltip: 'Copy details',
              ),
            ],
          ),

          SizedBox(height: 3.w),

          // Details
          _buildDetailItem('Details:', method.details, Icons.info),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.textMedium,
              size: 4.w,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.w),
        Padding(
          padding: EdgeInsets.only(left: 6.w),
          child: SelectableText(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.white,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            const Text('Copied to clipboard'),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.w),
        ),
      ),
    );
  }
}
