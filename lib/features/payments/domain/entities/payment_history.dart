// lib/features/payments/domain/entities/payment_history.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PaymentHistory extends Equatable {
  final String id;
  final String paymentId;
  final String studentId;
  final double amount;
  final double? discount;
  final String previousStatus;
  final String newStatus;
  final DateTime date;
  final String? remarks;
  final String recordedBy;
  final DateTime createdAt;

  const PaymentHistory({
    required this.id,
    required this.paymentId,
    required this.studentId,
    required this.amount,
    this.discount,
    required this.previousStatus,
    required this.newStatus,
    required this.date,
    this.remarks,
    required this.recordedBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        paymentId,
        studentId,
        date,
      ];

  // Factory method to create from Firestore document
  factory PaymentHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PaymentHistory(
      id: doc.id,
      paymentId: data['paymentId'] ?? '',
      studentId: data['studentId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      discount: data['discount'] != null
          ? (data['discount'] as num).toDouble()
          : null,
      previousStatus: data['previousStatus'] ?? '',
      newStatus: data['newStatus'] ?? '',
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      remarks: data['remarks'],
      recordedBy: data['recordedBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'paymentId': paymentId,
      'studentId': studentId,
      'amount': amount,
      'previousStatus': previousStatus,
      'newStatus': newStatus,
      'date': Timestamp.fromDate(date),
      'recordedBy': recordedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    // Only add optional fields if they have values
    if (remarks != null) {
      data['remarks'] = remarks;
    }

    if (discount != null) {
      data['discount'] = discount;
    }

    return data;
  }
}
