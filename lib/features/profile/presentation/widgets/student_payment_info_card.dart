import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/payments/domain/entities/payment_info.dart';

class StudentPaymentInfoCard extends StatelessWidget {
  final PaymentInfo paymentInfo;

  const StudentPaymentInfoCard({
    Key? key,
    required this.paymentInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasAnyPaymentMethod = paymentInfo.bankAccounts.isNotEmpty ||
        paymentInfo.eWallets.isNotEmpty ||
        paymentInfo.otherMethods.isNotEmpty;

    if (!hasAnyPaymentMethod) {
      return _buildEmptyState();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Removed the "Payment Methods" header section since it's redundant

            // Info message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlueLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryBlueLight.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Use any of the payment methods below to make your payments',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bank Accounts Section
            if (paymentInfo.bankAccounts.isNotEmpty) ...[
              _buildSectionHeader('🏦 Bank Accounts'),
              const SizedBox(height: 12),
              ...paymentInfo.bankAccounts
                  .where((account) => account.isActive)
                  .map((account) => _buildBankAccountItem(account, context)),
              const SizedBox(height: 20),
            ],

            // E-Wallets Section
            if (paymentInfo.eWallets.isNotEmpty) ...[
              _buildSectionHeader('💳 E-Wallets'),
              const SizedBox(height: 12),
              ...paymentInfo.eWallets
                  .where((wallet) => wallet.isActive)
                  .map((wallet) => _buildEWalletItem(wallet, context)),
              const SizedBox(height: 20),
            ],

            // Other Payment Methods Section
            if (paymentInfo.otherMethods.isNotEmpty) ...[
              _buildSectionHeader('💰 Other Methods'),
              const SizedBox(height: 12),
              ...paymentInfo.otherMethods
                  .where((method) => method.isActive)
                  .map((method) => _buildOtherMethodItem(method, context)),
              const SizedBox(height: 20),
            ],

            // Additional Information
            if (paymentInfo.additionalInfo.isNotEmpty) ...[
              _buildSectionHeader('📋 Additional Information'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.backgroundDark,
                  ),
                ),
                child: Text(
                  paymentInfo.additionalInfo,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payment_outlined,
                size: 48,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Payment Methods Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Payment information will be available once your tutor sets up the payment methods.',
              style: TextStyle(
                fontSize: 14,
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
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildBankAccountItem(BankAccount account, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  account.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    _copyToClipboard(context, account.accountNumber),
                icon: const Icon(
                  Icons.copy,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                tooltip: 'Copy account number',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Account Holder - Column Layout
          _buildDetailItem(
            'Account Holder:',
            account.accountHolder,
            Icons.person,
          ),

          const SizedBox(height: 12),

          // Account Number - Column Layout
          _buildDetailItem(
            'Account Number:',
            account.accountNumber,
            Icons.numbers,
          ),
        ],
      ),
    );
  }

  Widget _buildEWalletItem(EWallet wallet, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentOrange.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with wallet info and copy button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.accentOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  wallet.type,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(context, wallet.number),
                icon: const Icon(
                  Icons.copy,
                  color: AppColors.accentOrange,
                  size: 20,
                ),
                tooltip: 'Copy number/ID',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Account Name - Column Layout
          _buildDetailItem(
            'Account Name:',
            wallet.name,
            Icons.person,
          ),

          const SizedBox(height: 12),

          // Number/ID - Column Layout
          _buildDetailItem(
            'Number/ID:',
            wallet.number,
            Icons.phone_android,
          ),
        ],
      ),
    );
  }

  Widget _buildOtherMethodItem(
      OtherPaymentMethod method, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentTeal.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with method name and copy button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payment,
                  color: AppColors.accentTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  method.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(context, method.details),
                icon: const Icon(
                  Icons.copy,
                  color: AppColors.accentTeal,
                  size: 20,
                ),
                tooltip: 'Copy details',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Details - Column Layout
          _buildDetailItem(
            'Details:',
            method.details,
            Icons.info,
          ),
        ],
      ),
    );
  }

  // New helper method to build detail items in column format
  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row with icon
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.textMedium,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Value (indented to align with text, not icon)
        Padding(
          padding: const EdgeInsets.only(left: 24), // 16 (icon) + 8 (spacing)
          child: SelectableText(
            value,
            style: const TextStyle(
              fontSize: 15,
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
            const Icon(
              Icons.check_circle,
              color: AppColors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Copied to clipboard'),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
