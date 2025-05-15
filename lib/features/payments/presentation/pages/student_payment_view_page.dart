// lib/features/payments/presentation/pages/student_payment_view_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../bloc/payment_bloc.dart';
import '../../domain/entities/payment.dart';

class StudentPaymentViewPage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentPaymentViewPage({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<StudentPaymentViewPage> createState() => _StudentPaymentViewPageState();
}

class _StudentPaymentViewPageState extends State<StudentPaymentViewPage> {
  @override
  void initState() {
    super.initState();
    // Load student payments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentBloc>().add(
            LoadStudentPaymentsEvent(studentId: widget.studentId),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName}\'s Payments'),
      ),
      body: BlocBuilder<PaymentBloc, PaymentState>(
        builder: (context, state) {
          if (state is PaymentLoading && !(state is StudentPaymentsLoaded)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StudentPaymentsLoaded) {
            final payments = state.payments;

            // Separate payments into outstanding and completed
            final outstandingPayments =
                payments.where((p) => p.status != 'paid').toList();

            final completedPayments =
                payments.where((p) => p.status == 'paid').toList();

            // Display payment details
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card with payment details
                  _buildPaymentInfoCard(outstandingPayments),

                  const SizedBox(height: 24),

                  // Outstanding payments
                  if (outstandingPayments.isNotEmpty) ...[
                    const Text(
                      'Outstanding Payments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...outstandingPayments
                        .map((payment) => _buildPaymentCard(payment, false)),
                    const SizedBox(height: 24),
                  ],

                  // Payment history
                  const Text(
                    'Payment History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (completedPayments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Text(
                          'No payment history available',
                          style: TextStyle(
                            color: AppColors.textMedium,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  else
                    ...completedPayments
                        .map((payment) => _buildPaymentCard(payment, true)),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Failed to load payment information'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<PaymentBloc>().add(
                          LoadStudentPaymentsEvent(studentId: widget.studentId),
                        );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentInfoCard(List<Payment> outstandingPayments) {
    // Calculate total outstanding amount
    double totalOutstanding = 0;
    for (final payment in outstandingPayments) {
      totalOutstanding += payment.amount;
    }

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
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getAvatarColor(widget.studentName),
                  child: Text(
                    widget.studentName.isNotEmpty
                        ? widget.studentName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.studentName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${widget.studentId}',
                        style: TextStyle(
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Payment summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Outstanding:',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'RM ${totalOutstanding.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: totalOutstanding > 0
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Unpaid Months:',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  outstandingPayments.isEmpty
                      ? 'None'
                      : '${outstandingPayments.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: outstandingPayments.isEmpty
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),

            if (outstandingPayments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Payment Information:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please make payment to:',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              // Bank account details
              const Text(
                'Bank: Maybank\nAccount: 1234 5678 9012\nName: MyTuition Sdn Bhd',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              // E-wallet details
              const Text(
                'E-Wallet: Touch n Go eWallet\nPhone: 012-3456789',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              // Reference note
              Text(
                'Please include your Student ID (${widget.studentId}) as reference when making payment.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment, bool isPaid) {
    final isPartial = payment.status == 'partial';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Month/Year indicator
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isPaid
                    ? AppColors.successLight
                    : isPartial
                        ? AppColors.warningLight
                        : AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getShortMonthName(payment.month),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPaid
                          ? AppColors.success
                          : isPartial
                              ? AppColors.warning
                              : AppColors.error,
                    ),
                  ),
                  Text(
                    payment.year.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isPaid
                          ? AppColors.success
                          : isPartial
                              ? AppColors.warning
                              : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Payment details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getMonthName(payment.month)} ${payment.year}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isPaid && payment.paidDate != null)
                    Text(
                      'Paid on: ${DateFormat('dd MMM yyyy').format(payment.paidDate!)}',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 14,
                      ),
                    )
                  else
                    Text(
                      'Status: ${payment.status[0].toUpperCase()}${payment.status.substring(1)}',
                      style: TextStyle(
                        color: isPaid
                            ? AppColors.success
                            : isPartial
                                ? AppColors.warning
                                : AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                  if (payment.remarks != null && payment.remarks!.isNotEmpty)
                    Text(
                      'Note: ${payment.remarks}',
                      style: TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM ${payment.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPaid ? AppColors.success : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2022, month));
  }

  String _getShortMonthName(int month) {
    return DateFormat('MMM').format(DateTime(2022, month));
  }

  Color _getAvatarColor(String name) {
    final List<Color> colors = [
      AppColors.primaryBlue,
      AppColors.accentOrange,
      AppColors.accentTeal,
      AppColors.mathSubject,
      AppColors.scienceSubject,
      AppColors.englishSubject,
      AppColors.bahasaSubject,
      AppColors.chineseSubject,
    ];

    if (name.isEmpty) return colors[0];

    // Use a simple hash function to get a consistent color for the same name
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = (hash + name.codeUnitAt(i)) % colors.length;
    }

    return colors[hash];
  }
}
