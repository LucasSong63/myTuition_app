import 'package:mytuition/features/payments/domain/entities/payment_history.dart';

class PaymentHistoryWithStudent extends PaymentHistory {
  final String studentName;
  final int month;
  final int year;

  const PaymentHistoryWithStudent({
    required String id,
    required String paymentId,
    required String studentId,
    required this.studentName,
    required double amount,
    required String previousStatus,
    required String newStatus,
    required DateTime date,
    String? remarks,
    required String recordedBy,
    required DateTime createdAt,
    required this.month,
    required this.year,
  }) : super(
          id: id,
          paymentId: paymentId,
          studentId: studentId,
          amount: amount,
          previousStatus: previousStatus,
          newStatus: newStatus,
          date: date,
          remarks: remarks,
          recordedBy: recordedBy,
          createdAt: createdAt,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        studentName,
        month,
        year,
      ];
}
