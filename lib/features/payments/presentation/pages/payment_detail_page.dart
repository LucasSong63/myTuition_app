// lib/features/payments/presentation/pages/payment_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../bloc/payment_bloc.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/payment_history.dart';

class PaymentDetailPage extends StatefulWidget {
  final Payment payment;
  final VoidCallback onPaymentUpdated;

  const PaymentDetailPage({
    Key? key,
    required this.payment,
    required this.onPaymentUpdated,
  }) : super(key: key);

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  double _amountPaid = 0.0;
  double _discount = 0.0;
  double _outstandingAmount = 0.0;
  String _paymentStatus = '';

  @override
  void initState() {
    super.initState();
    // Initialize with the current payment amount for the outstanding amount
    _outstandingAmount = widget.payment.amount;
    _paymentStatus = widget.payment.status;

    // Set controllers initial values
    _amountController.text = "0.00";
    _discountController.text = "0.00";

    // Add listeners to update calculations
    _amountController.addListener(_updateCalculation);
    _discountController.addListener(_updateCalculation);

    // Load payment history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentBloc>().add(
            LoadPaymentHistoryEvent(paymentId: widget.payment.id),
          );
    });
  }

  void _updateCalculation() {
    setState(() {
      // Parse amount paid and discount for this transaction
      _amountPaid = double.tryParse(_amountController.text) ?? 0.0;
      _discount = double.tryParse(_discountController.text) ?? 0.0;

      // Ensure discount doesn't exceed total amount
      if (_discount > widget.payment.amount) {
        _discount = widget.payment.amount;
        _discountController.text = _discount.toStringAsFixed(2);
      }

      // Calculate outstanding amount AFTER this payment
      // Start with current outstanding from the payment entity
      double currentOutstanding = widget.payment.getOutstandingAmount();

      // Subtract this transaction's amount and discount
      _outstandingAmount = currentOutstanding - _amountPaid - _discount;

      // Ensure outstanding doesn't go negative
      if (_outstandingAmount < 0) {
        _outstandingAmount = 0.0;
      }

      // Determine payment status after this transaction
      if (_outstandingAmount <= 0) {
        _paymentStatus = 'paid';
      } else if (_amountPaid > 0) {
        _paymentStatus = 'partial';
      } else {
        _paymentStatus = widget.payment.status; // Keep current status
      }
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateCalculation);
    _discountController.removeListener(_updateCalculation);
    _amountController.dispose();
    _discountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Details',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
                backgroundColor: AppColors.error,
              ),
            );
          }

          if (state is PaymentRecorded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
                backgroundColor: AppColors.success,
              ),
            );

            widget.onPaymentUpdated();
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student information card
                _buildStudentInfoCard(),

                SizedBox(height: 4.h),

                // Payment form
                if (widget.payment.status != 'paid') _buildPaymentForm(context),

                if (widget.payment.status == 'paid') _buildPaidStatusCard(),

                SizedBox(height: 4.h),

                // Payment history section
                Text(
                  'Payment History',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 3.h),

                // Payment history list
                if (state is PaymentLoading && !(state is PaymentHistoryLoaded))
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  )
                else if (state is PaymentHistoryLoaded)
                  _buildPaymentHistoryList(state.history)
                else
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        'No payment history available',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    final isPaid = widget.payment.status == 'paid';
    final isPartial = widget.payment.status == 'partial';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with name and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.payment.studentName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 4.w,
                            color: AppColors.textMedium,
                          ),
                          SizedBox(width: 1.5.w),
                          Text(
                            'ID: ${widget.payment.studentId}',
                            style: TextStyle(
                              color: AppColors.textMedium,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? AppColors.successLight
                        : isPartial
                            ? AppColors.warningLight
                            : AppColors.errorLight,
                    borderRadius: BorderRadius.circular(5.w),
                  ),
                  child: Text(
                    isPaid
                        ? 'Paid'
                        : isPartial
                            ? 'Partial'
                            : 'Unpaid',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: isPaid
                          ? AppColors.success
                          : isPartial
                              ? AppColors.warning
                              : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),
            const Divider(),
            SizedBox(height: 3.h),

            // Payment details
            _buildInfoRow('Month', _getMonthName(widget.payment.month)),
            _buildInfoRow('Year', widget.payment.year.toString()),
            _buildInfoRow(
              'Amount',
              'RM ${widget.payment.amount.toStringAsFixed(2)}',
            ),
            if (widget.payment.paidDate != null)
              _buildInfoRow(
                'Paid On',
                DateFormat('dd MMM yyyy').format(widget.payment.paidDate!),
              ),
            if (widget.payment.remarks != null &&
                widget.payment.remarks!.isNotEmpty)
              _buildInfoRow('Remarks', widget.payment.remarks!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidStatusCard() {
    return Card(
      color: AppColors.successLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 6.w,
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Completed',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Payment was recorded on ${widget.payment.paidDate != null ? DateFormat('dd MMM yyyy').format(widget.payment.paidDate!) : 'N/A'}',
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record Payment',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 3.h),

            // Amount paid field
            TextField(
              controller: _amountController,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                labelText: 'Amount Paid (RM)',
                labelStyle: TextStyle(fontSize: 14.sp),
                hintText: 'Enter payment amount',
                hintStyle: TextStyle(fontSize: 13.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
                prefixIcon: Icon(Icons.payments_outlined, size: 5.w),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 3.5.h,
                ),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            SizedBox(height: 3.h),

            // Discount field
            TextField(
              controller: _discountController,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                labelText: 'Discount (RM)',
                labelStyle: TextStyle(fontSize: 14.sp),
                hintText: 'Enter discount amount (if any)',
                hintStyle: TextStyle(fontSize: 13.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
                prefixIcon: Icon(Icons.discount_outlined, size: 5.w),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 3.5.h,
                ),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            SizedBox(height: 3.h),

            // Payment summary
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(2.w),
                border: Border.all(color: AppColors.backgroundDark),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Total Amount', widget.payment.amount),
                  _buildSummaryRow(
                      'Previously Paid', widget.payment.amountPaid ?? 0.0),
                  _buildSummaryRow(
                      'Previous Discount', widget.payment.discount ?? 0.0),
                  _buildSummaryRow('Current Outstanding',
                      widget.payment.getOutstandingAmount(),
                      color: AppColors.warning),
                  Divider(height: 3.h),
                  _buildSummaryRow('This Payment', _amountPaid),
                  _buildSummaryRow('This Discount', _discount),
                  Divider(height: 3.h),
                  _buildSummaryRow('New Outstanding', _outstandingAmount,
                      highlight: true,
                      color: _outstandingAmount > 0
                          ? AppColors.error
                          : AppColors.success),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Text(
                        'New Status: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(_paymentStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(1.5.w),
                        ),
                        child: Text(
                          _paymentStatus.substring(0, 1).toUpperCase() +
                              _paymentStatus.substring(1),
                          style: TextStyle(
                            color: _getStatusColor(_paymentStatus),
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),

            // Remarks field
            TextField(
              controller: _remarksController,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                labelText: 'Remarks',
                labelStyle: TextStyle(fontSize: 14.sp),
                hintText: 'Add any notes about this payment',
                hintStyle: TextStyle(fontSize: 13.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 3.5.h,
                ),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 4.h),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: BlocBuilder<PaymentBloc, PaymentState>(
                builder: (context, state) {
                  final isLoading = state is PaymentLoading;
                  final buttonText = _paymentStatus == 'paid'
                      ? 'Record Full Payment'
                      : _paymentStatus == 'partial'
                          ? 'Record Partial Payment'
                          : 'Record Payment';
                  final buttonColor = _paymentStatus == 'paid'
                      ? AppColors.success
                      : AppColors.primaryBlue;

                  return ElevatedButton(
                    onPressed: isLoading ? null : () => _recordPayment(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      padding: EdgeInsets.symmetric(vertical: 3.5.h),
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
                            buttonText,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount,
      {bool highlight = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              fontSize: highlight ? 15.sp : 13.sp,
              color: AppColors.textDark,
            ),
          ),
          Text(
            'RM ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              fontSize: highlight ? 15.sp : 13.sp,
              color: color ?? AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryList(List<PaymentHistory> history) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 12.w,
              color: AppColors.textLight,
            ),
            SizedBox(height: 3.h),
            Text(
              'No payment history found',
              style: TextStyle(
                color: AppColors.textMedium,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Icon(
                    Icons.monetization_on,
                    color: AppColors.primaryBlue,
                    size: 5.w,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RM ${item.amount.toStringAsFixed(2)} received',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Status changed from ${item.previousStatus} to ${item.newStatus}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textMedium,
                        ),
                      ),
                      if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                        SizedBox(height: 1.h),
                        Text(
                          'Note: ${item.remarks}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textMedium,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd MMM').format(item.date),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _recordPayment(BuildContext context) {
    // Validate amount
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid amount',
            style: TextStyle(fontSize: 14.sp),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amountPaid = double.tryParse(amountText);
    if (amountPaid == null || amountPaid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid amount greater than zero',
            style: TextStyle(fontSize: 14.sp),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get discount
    final discountText = _discountController.text.trim();
    final discount = double.tryParse(discountText) ?? 0.0;

    // Get remarks
    final remarks = _remarksController.text.trim();

    // Create payment record with additional details
    final updatedPayment = widget.payment.copyWith(
      status: _paymentStatus,
      amount: widget.payment.amount -
          discount, // Adjust total amount after discount
    );

    // Record payment with all details
    context.read<PaymentBloc>().add(
          RecordPaymentEvent(
            payment: updatedPayment,
            amount: amountPaid,
            discount: discount,
            remarks: remarks,
            recordedBy: 'tutor-leong', // Should come from auth
          ),
        );
  }

  String _getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2022, month));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'partial':
        return AppColors.warning;
      case 'unpaid':
      default:
        return AppColors.error;
    }
  }
}
