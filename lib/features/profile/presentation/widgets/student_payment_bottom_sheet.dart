// lib/features/profile/presentation/widgets/student_payment_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/profile/domain/entities/student_payment_summary.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_event.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_state.dart';

class StudentPaymentBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required String studentId,
  }) async {
    // Get the existing bloc from the parent context
    final ProfileBloc parentBloc = context.read<ProfileBloc>();

    // Define the page content builder function
    WoltModalSheetPage pageBuilder(BuildContext context) {
      return WoltModalSheetPage(
        hasSabGradient: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        topBarTitle: const Text(
          'Payment Information',
          style: TextStyle(
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
                  child: _StudentPaymentContent(
                    studentId: studentId,
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

class _StudentPaymentContent extends StatefulWidget {
  final String studentId;

  const _StudentPaymentContent({
    required this.studentId,
  });

  @override
  State<_StudentPaymentContent> createState() => _StudentPaymentContentState();
}

class _StudentPaymentContentState extends State<_StudentPaymentContent> {
  @override
  void initState() {
    super.initState();
    // Load payment summary when sheet opens
    context.read<ProfileBloc>().add(
          LoadStudentPaymentSummaryEvent(studentId: widget.studentId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is StudentPaymentSummaryLoading) {
          return _buildLoadingContent();
        }

        if (state is StudentPaymentSummaryError) {
          return _buildErrorContent(state.message);
        }

        if (state is StudentPaymentSummaryLoaded) {
          return _buildPaymentContent(state.paymentSummary);
        }

        // Initial state or other states
        return _buildLoadingContent();
      },
    );
  }

  Widget _buildLoadingContent() {
    return Padding(
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10.h),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
          SizedBox(height: 3.h),
          Text(
            'Loading payment information...',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textMedium,
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildErrorContent(String message) {
    return Padding(
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 5.h),
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 15.w,
          ),
          SizedBox(height: 3.h),
          Text(
            'Unable to load payment information',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ProfileBloc>().add(
                    LoadStudentPaymentSummaryEvent(studentId: widget.studentId),
                  );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
            ),
          ),
          SizedBox(height: 5.h),
        ],
      ),
    );
  }

  Widget _buildPaymentContent(StudentPaymentSummary summary) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Outstanding amount summary
          _buildOutstandingSummary(summary),

          if (summary.hasOutstandingPayments) ...[
            SizedBox(height: 3.h),
            _buildOutstandingPaymentsList(summary.outstandingPayments),
          ],

          if (summary.recentTransactions.isNotEmpty) ...[
            SizedBox(height: 3.h),
            _buildRecentTransactionsList(summary.recentTransactions),
          ],

          // Bottom spacing
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildOutstandingSummary(StudentPaymentSummary summary) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3.w),
          gradient: summary.hasOutstandingPayments
              ? LinearGradient(
                  colors: [
                    AppColors.warning.withOpacity(0.1),
                    AppColors.error.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    AppColors.success.withOpacity(0.1),
                    AppColors.primaryBlue.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Column(
          children: [
            Icon(
              summary.hasOutstandingPayments
                  ? Icons.account_balance_wallet_outlined
                  : Icons.check_circle_outline,
              size: 15.w,
              color: summary.hasOutstandingPayments
                  ? AppColors.warning
                  : AppColors.success,
            ),
            SizedBox(height: 2.h),
            Text(
              summary.hasOutstandingPayments
                  ? 'Outstanding Amount'
                  : 'All Payments Up to Date!',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            if (summary.hasOutstandingPayments) ...[
              Text(
                'RM ${summary.totalOutstanding.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              if (summary.unpaidCount > 0 || summary.partialCount > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (summary.unpaidCount > 0) ...[
                      _buildStatusChip(
                        '${summary.unpaidCount} Unpaid',
                        AppColors.error,
                      ),
                    ],
                    if (summary.unpaidCount > 0 && summary.partialCount > 0)
                      SizedBox(width: 2.w),
                    if (summary.partialCount > 0) ...[
                      _buildStatusChip(
                        '${summary.partialCount} Partial',
                        AppColors.warning,
                      ),
                    ],
                  ],
                ),
              ],
            ] else ...[
              Text(
                'You have no outstanding payments',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5.w),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildOutstandingPaymentsList(List<OutstandingPayment> payments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outstanding Payments',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 1.5.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          separatorBuilder: (context, index) => SizedBox(height: 1.5.h),
          itemBuilder: (context, index) =>
              _buildOutstandingPaymentCard(payments[index]),
        ),
      ],
    );
  }

  Widget _buildOutstandingPaymentCard(OutstandingPayment payment) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
        side: BorderSide(
          color: payment.status == 'unpaid'
              ? AppColors.error.withOpacity(0.3)
              : AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  payment.monthYearDisplay,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: payment.status == 'unpaid'
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Text(
                    payment.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: payment.status == 'unpaid'
                          ? AppColors.error
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMedium,
                      ),
                    ),
                    Text(
                      'RM ${payment.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                if (payment.amountPaid > 0) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paid',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textMedium,
                        ),
                      ),
                      Text(
                        'RM ${payment.amountPaid.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Outstanding',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMedium,
                      ),
                    ),
                    Text(
                      'RM ${payment.outstandingAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsList(
      List<RecentPaymentTransaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 1.5.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length > 5 ? 5 : transactions.length,
          // Show max 5
          separatorBuilder: (context, index) => SizedBox(height: 1.h),
          itemBuilder: (context, index) =>
              _buildTransactionCard(transactions[index]),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(RecentPaymentTransaction transaction) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.w)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Icon(
                Icons.payment,
                color: AppColors.success,
                size: 5.w,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${transaction.monthYearDisplay} Payment',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(transaction.date),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM ${transaction.effectiveAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                if (transaction.discount > 0) ...[
                  Text(
                    'Discount: RM ${transaction.discount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.accentOrange,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
