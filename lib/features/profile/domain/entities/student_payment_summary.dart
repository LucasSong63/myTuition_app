// lib/features/profile/domain/entities/student_payment_summary.dart

import 'package:equatable/equatable.dart';

class StudentPaymentSummary extends Equatable {
  final double totalOutstanding;
  final int unpaidCount;
  final int partialCount;
  final List<OutstandingPayment> outstandingPayments;
  final List<RecentPaymentTransaction> recentTransactions;

  const StudentPaymentSummary({
    required this.totalOutstanding,
    required this.unpaidCount,
    required this.partialCount,
    required this.outstandingPayments,
    required this.recentTransactions,
  });

  bool get hasOutstandingPayments => totalOutstanding > 0;

  @override
  List<Object?> get props => [
        totalOutstanding,
        unpaidCount,
        partialCount,
        outstandingPayments,
        recentTransactions,
      ];
}

class OutstandingPayment extends Equatable {
  final String id;
  final String studentId;
  final int month;
  final int year;
  final double totalAmount;
  final double amountPaid;
  final double outstandingAmount;
  final String status;
  final DateTime createdAt;

  const OutstandingPayment({
    required this.id,
    required this.studentId,
    required this.month,
    required this.year,
    required this.totalAmount,
    required this.amountPaid,
    required this.outstandingAmount,
    required this.status,
    required this.createdAt,
  });

  String get monthYearDisplay {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[month - 1]} $year';
  }

  @override
  List<Object?> get props => [
        id,
        studentId,
        month,
        year,
        totalAmount,
        amountPaid,
        outstandingAmount,
        status,
        createdAt,
      ];
}

class RecentPaymentTransaction extends Equatable {
  final String id;
  final String paymentId;
  final double amount;
  final double discount;
  final String status;
  final DateTime date;
  final String? remarks;
  final int month;
  final int year;

  const RecentPaymentTransaction({
    required this.id,
    required this.paymentId,
    required this.amount,
    required this.discount,
    required this.status,
    required this.date,
    this.remarks,
    required this.month,
    required this.year,
  });

  String get monthYearDisplay {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[month - 1]} $year';
  }

  double get effectiveAmount => amount + discount;

  @override
  List<Object?> get props => [
        id,
        paymentId,
        amount,
        discount,
        status,
        date,
        remarks,
        month,
        year,
      ];
}
