// lib/features/payments/presentation/bloc/payment_event.dart

part of 'payment_bloc.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object> get props => [];
}

class LoadPaymentsByMonthEvent extends PaymentEvent {
  final int month;
  final int year;

  const LoadPaymentsByMonthEvent({
    required this.month,
    required this.year,
  });

  @override
  List<Object> get props => [month, year];
}

class LoadStudentPaymentEvent extends PaymentEvent {
  final String studentId;
  final int month;
  final int year;

  const LoadStudentPaymentEvent({
    required this.studentId,
    required this.month,
    required this.year,
  });

  @override
  List<Object> get props => [studentId, month, year];
}

class LoadStudentPaymentsEvent extends PaymentEvent {
  final String studentId;

  const LoadStudentPaymentsEvent({
    required this.studentId,
  });

  @override
  List<Object> get props => [studentId];
}

class RecordPaymentEvent extends PaymentEvent {
  final Payment payment;
  final double amount;
  final double discount;
  final String remarks;
  final String recordedBy;

  const RecordPaymentEvent({
    required this.payment,
    required this.amount,
    this.discount = 0.0,
    required this.remarks,
    required this.recordedBy,
  });

  @override
  List<Object> get props => [payment, amount, discount, remarks, recordedBy];
}

class LoadPaymentHistoryEvent extends PaymentEvent {
  final String paymentId;

  const LoadPaymentHistoryEvent({
    required this.paymentId,
  });

  @override
  List<Object> get props => [paymentId];
}

class LoadStudentPaymentHistoryEvent extends PaymentEvent {
  final String studentId;

  const LoadStudentPaymentHistoryEvent({
    required this.studentId,
  });

  @override
  List<Object> get props => [studentId];
}

class GenerateMonthlyPaymentsEvent extends PaymentEvent {
  final int month;
  final int year;
  final double defaultAmount;

  const GenerateMonthlyPaymentsEvent({
    required this.month,
    required this.year,
    this.defaultAmount = 100.0, // Default amount for monthly tuition
  });

  @override
  List<Object> get props => [month, year, defaultAmount];
}

class BulkMarkPaymentsAsPaidEvent extends PaymentEvent {
  final List<Payment> payments;
  final String remarks;
  final String recordedBy;
  final bool sendNotification;
  final double discount;

  const BulkMarkPaymentsAsPaidEvent({
    required this.payments,
    required this.remarks,
    required this.recordedBy,
    this.sendNotification = true,
    this.discount = 0.0,
  });

  @override
  List<Object> get props =>
      [payments, remarks, recordedBy, sendNotification, discount];
}

class SendPaymentRemindersEvent extends PaymentEvent {
  final List<Payment> payments;
  final String message;

  const SendPaymentRemindersEvent({
    required this.payments,
    required this.message,
  });

  @override
  List<Object> get props => [payments, message];
}

class SendAllUnpaidRemindersEvent extends PaymentEvent {
  final int month;
  final int year;
  final String message;

  const SendAllUnpaidRemindersEvent({
    required this.month,
    required this.year,
    required this.message,
  });

  @override
  List<Object> get props => [month, year, message];
}

class LoadAllPaymentHistoryEvent extends PaymentEvent {}

class CheckStudentPaymentStatusEvent extends PaymentEvent {
  final String studentId;

  const CheckStudentPaymentStatusEvent({required this.studentId});

  @override
  List<Object> get props => [studentId];
}

class GetStudentPaymentStatsEvent extends PaymentEvent {
  final String studentId;

  const GetStudentPaymentStatsEvent({required this.studentId});

  @override
  List<Object> get props => [studentId];
}

class CreatePaymentEvent extends PaymentEvent {
  final Payment payment;

  const CreatePaymentEvent({required this.payment});

  @override
  List<Object> get props => [payment];
}

// New events for handling mid-month enrollments
class GeneratePaymentForStudentEvent extends PaymentEvent {
  final String userDocId;
  final int month;
  final int year;

  const GeneratePaymentForStudentEvent({
    required this.userDocId,
    required this.month,
    required this.year,
  });

  @override
  List<Object> get props => [userDocId, month, year];
}

class GenerateMissingPaymentsEvent extends PaymentEvent {
  final int month;
  final int year;

  const GenerateMissingPaymentsEvent({
    required this.month,
    required this.year,
  });

  @override
  List<Object> get props => [month, year];
}
