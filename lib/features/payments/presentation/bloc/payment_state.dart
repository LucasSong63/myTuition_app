// lib/features/payments/presentation/bloc/payment_state.dart

part of 'payment_bloc.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentsByMonthLoaded extends PaymentState {
  final List<Payment> payments;
  final int month;
  final int year;

  const PaymentsByMonthLoaded({
    required this.payments,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [payments, month, year];
}

class StudentPaymentLoaded extends PaymentState {
  final Payment payment;

  const StudentPaymentLoaded({
    required this.payment,
  });

  @override
  List<Object?> get props => [payment];
}

class StudentPaymentsLoaded extends PaymentState {
  final List<Payment> payments;
  final String studentId;

  const StudentPaymentsLoaded({
    required this.payments,
    required this.studentId,
  });

  @override
  List<Object?> get props => [payments, studentId];
}

class PaymentHistoryLoaded extends PaymentState {
  final List<PaymentHistory> history;

  const PaymentHistoryLoaded({
    required this.history,
  });

  @override
  List<Object?> get props => [history];
}

class StudentPaymentHistoryLoaded extends PaymentState {
  final List<PaymentHistory> history;
  final String studentId;

  const StudentPaymentHistoryLoaded({
    required this.history,
    required this.studentId,
  });

  @override
  List<Object?> get props => [history, studentId];
}

class PaymentRecorded extends PaymentState {
  final Payment payment;
  final String message;

  const PaymentRecorded({
    required this.payment,
    required this.message,
  });

  @override
  List<Object?> get props => [payment, message];
}

class PaymentOperationSuccess extends PaymentState {
  final String message;

  const PaymentOperationSuccess({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

class PaymentNotFound extends PaymentState {}

class AllPaymentHistoryLoaded extends PaymentState {
  final List<PaymentHistoryWithStudent> history;

  const AllPaymentHistoryLoaded({
    required this.history,
  });

  @override
  List<Object?> get props => [history];
}

class StudentPaymentStatusChecked extends PaymentState {
  final bool hasOutstandingPayments;
  final String studentId;

  const StudentPaymentStatusChecked({
    required this.hasOutstandingPayments,
    required this.studentId,
  });

  @override
  List<Object?> get props => [hasOutstandingPayments, studentId];
}

class StudentPaymentStatsLoaded extends PaymentState {
  final Map<String, dynamic> stats;
  final String studentId;

  const StudentPaymentStatsLoaded({
    required this.stats,
    required this.studentId,
  });

  @override
  List<Object?> get props => [stats, studentId];
}
