// lib/features/payments/presentation/pages/payment_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
      // Parse amount paid and discount
      _amountPaid = double.tryParse(_amountController.text) ?? 0.0;
      _discount = double.tryParse(_discountController.text) ?? 0.0;

      // Ensure discount doesn't exceed total amount
      if (_discount > widget.payment.amount) {
        _discount = widget.payment.amount;
        _discountController.text = _discount.toStringAsFixed(2);
      }

      // Calculate outstanding
      _outstandingAmount = widget.payment.amount - _amountPaid - _discount;
      if (_outstandingAmount < 0) {
        _outstandingAmount = 0.0;
      }

      // Determine payment status
      if (_outstandingAmount <= 0) {
        _paymentStatus = 'paid';
      } else if (_amountPaid > 0) {
        _paymentStatus = 'partial';
      } else {
        _paymentStatus = 'unpaid';
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
        title: const Text('Payment Details'),
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }

          if (state is PaymentRecorded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );

            widget.onPaymentUpdated();
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student information card
                _buildStudentInfoCard(),

                const SizedBox(height: 24),

                // Payment form
                if (widget.payment.status != 'paid') _buildPaymentForm(context),

                if (widget.payment.status == 'paid') _buildPaidStatusCard(),

                const SizedBox(height: 24),

                // Payment history section
                const Text(
                  'Payment History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Payment history list
                if (state is PaymentLoading && !(state is PaymentHistoryLoaded))
                  const Center(child: CircularProgressIndicator())
                else if (state is PaymentHistoryLoaded)
                  _buildPaymentHistoryList(state.history)
                else
                  const Center(
                    child: Text('No payment history available'),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.payment.studentId}',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? AppColors.successLight
                        : isPartial
                            ? AppColors.warningLight
                            : AppColors.errorLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPaid
                        ? 'Paid'
                        : isPartial
                            ? 'Partial'
                            : 'Unpaid',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
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

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

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
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidStatusCard() {
    return Card(
      color: AppColors.successLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Completed',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Payment was recorded on ${widget.payment.paidDate != null ? DateFormat('dd MMM yyyy').format(widget.payment.paidDate!) : 'N/A'}',
                    style: TextStyle(
                      color: AppColors.textMedium,
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Record Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Amount paid field
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount Paid (RM)',
                hintText: 'Enter payment amount',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),

            // Discount field
            TextField(
              controller: _discountController,
              decoration: const InputDecoration(
                labelText: 'Discount (RM)',
                hintText: 'Enter discount amount (if any)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.discount_outlined),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),

            // Payment summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.backgroundDark),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Total Amount', widget.payment.amount),
                  _buildSummaryRow('Amount Paid', _amountPaid),
                  _buildSummaryRow('Discount', _discount),
                  const Divider(height: 16),
                  _buildSummaryRow('Outstanding', _outstandingAmount,
                      highlight: true,
                      color: _outstandingAmount > 0
                          ? AppColors.error
                          : AppColors.success),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Status: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(_paymentStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _paymentStatus.substring(0, 1).toUpperCase() +
                              _paymentStatus.substring(1),
                          style: TextStyle(
                            color: _getStatusColor(_paymentStatus),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Remarks field
            TextField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                hintText: 'Add any notes about this payment',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

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
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                            buttonText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              fontSize: highlight ? 16 : 14,
            ),
          ),
          Text(
            'RM ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              fontSize: highlight ? 16 : 14,
              color: color,
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
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No payment history found',
              style: TextStyle(color: AppColors.textMedium),
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
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RM ${item.amount.toStringAsFixed(2)} received',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status changed from ${item.previousStatus} to ${item.newStatus}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMedium,
                        ),
                      ),
                      if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Note: ${item.remarks}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMedium,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(item.date),
                  style: TextStyle(
                    fontSize: 12,
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
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amountPaid = double.tryParse(amountText);
    if (amountPaid == null || amountPaid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than zero'),
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
