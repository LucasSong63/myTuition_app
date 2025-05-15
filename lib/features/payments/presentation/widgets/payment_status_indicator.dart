// lib/features/payments/presentation/widgets/payment_status_indicator.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../bloc/payment_bloc.dart';

class PaymentStatusIndicator extends StatefulWidget {
  final String studentId;
  final String studentName;
  final bool compact;

  const PaymentStatusIndicator({
    Key? key,
    required this.studentId,
    required this.studentName,
    this.compact = false,
  }) : super(key: key);

  @override
  State<PaymentStatusIndicator> createState() => _PaymentStatusIndicatorState();
}

class _PaymentStatusIndicatorState extends State<PaymentStatusIndicator> {
  @override
  void initState() {
    super.initState();
    // Check payment status when widget is created
    context.read<PaymentBloc>().add(
          CheckStudentPaymentStatusEvent(studentId: widget.studentId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        if (state is PaymentLoading) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (state is StudentPaymentStatusChecked &&
            state.studentId == widget.studentId) {
          final hasOutstanding = state.hasOutstandingPayments;

          // Compact version (just an icon) for list items
          if (widget.compact) {
            return Icon(
              hasOutstanding ? Icons.warning : Icons.check_circle,
              size: 16,
              color: hasOutstanding ? AppColors.error : AppColors.success,
            );
          }

          // Full version with text label
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasOutstanding
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasOutstanding ? Icons.warning : Icons.check_circle,
                  size: 16,
                  color: hasOutstanding ? AppColors.error : AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  hasOutstanding ? 'Outstanding' : 'Cleared',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: hasOutstanding ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),
          );
        }

        // Default state - unknown payment status
        return const SizedBox.shrink();
      },
    );
  }
}
