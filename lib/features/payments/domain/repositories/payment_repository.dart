// lib/features/payments/domain/repositories/payment_repository.dart

import 'package:mytuition/features/payments/domain/entities/payment_history_with_student.dart';

import '../entities/payment.dart';
import '../entities/payment_history.dart';

abstract class PaymentRepository {
  /// Get all payments for a specific month and year
  Future<List<Payment>> getPaymentsByMonthYear(int month, int year);

  /// Get payment for a specific student by month and year
  Future<Payment?> getStudentPayment(String studentId, int month, int year);

  /// Get all payments for a specific student
  Future<List<Payment>> getStudentPayments(String studentId);

  /// Create a new payment record
  Future<void> createPayment(Payment payment);

  /// Update an existing payment record
  Future<void> updatePayment(Payment payment);

  /// Record a payment transaction and update the payment status
  Future<void> recordPayment(
      Payment payment, double amount, String remarks, String recordedBy,
      {double discount = 0.0});

  /// Get payment history for a specific payment
  Future<List<PaymentHistory>> getPaymentHistory(String paymentId);

  /// Get payment history for a specific student
  Future<List<PaymentHistory>> getStudentPaymentHistory(String studentId);

  /// Record payments for multiple students at once
  Future<void> recordBulkPayments(
      List<Payment> payments, String remarks, String recordedBy,
      {double discount = 0.0});

  /// Send payment reminders to specific students
  Future<void> sendPaymentReminders(List<Payment> payments, String message);

  /// Send reminders to all students with unpaid payments for a month/year
  Future<void> sendAllUnpaidReminders(int month, int year, String message);

  /// Get payment history with student information for reporting
  Future<List<PaymentHistoryWithStudent>> getAllPaymentHistory();

  /// Check if a student has any outstanding payments
  Future<bool> hasOutstandingPayments(String studentId);

  /// Calculate total outstanding amount for a student
  Future<double> calculateTotalOutstanding(String studentId);

  /// Get payment statistics for a student
  Future<Map<String, dynamic>> getStudentPaymentStats(String studentId);

  /// Generate monthly payments for all students
  Future<int> generateMonthlyPayments(
      int month, int year, double defaultAmount);
}
