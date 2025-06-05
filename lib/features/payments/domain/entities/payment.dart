// lib/features/payments/domain/entities/payment.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final String studentId;
  final String studentName;
  final int month;
  final int year;
  final double amount;
  final String status; // 'paid', 'unpaid', 'partial'
  final DateTime? paidDate;
  final double? discount;
  final double? amountPaid;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Payment({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.month,
    required this.year,
    required this.amount,
    required this.status,
    this.paidDate,
    this.discount,
    this.amountPaid,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        studentId,
        month,
        year,
        status,
      ];

  // Factory method to create from Firestore document
  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Payment(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      month: data['month'] ?? 0,
      year: data['year'] ?? 0,
      amount: (data['amount'] ?? 0).toDouble(),
      status: data['status'] ?? 'unpaid',
      paidDate: data['paidDate'] != null
          ? (data['paidDate'] as Timestamp).toDate()
          : null,
      discount: data['discount'] != null
          ? (data['discount'] as num).toDouble()
          : null,
      amountPaid: data['amountPaid'] != null
          ? (data['amountPaid'] as num).toDouble()
          : null,
      remarks: data['remarks'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'studentId': studentId,
      'studentName': studentName,
      'month': month,
      'year': year,
      'amount': amount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };

    // Only add optional fields if they have values
    if (paidDate != null) {
      data['paidDate'] = Timestamp.fromDate(paidDate!);
    }

    if (remarks != null) {
      data['remarks'] = remarks;
    }

    if (discount != null) {
      data['discount'] = discount;
    }

    if (amountPaid != null) {
      data['amountPaid'] = amountPaid;
    }

    return data;
  }

  // Create a copy with updated fields
  Payment copyWith({
    String? id,
    String? studentId,
    String? studentName,
    int? month,
    int? year,
    double? amount,
    String? status,
    DateTime? paidDate,
    double? discount,
    double? amountPaid,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      month: month ?? this.month,
      year: year ?? this.year,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paidDate: paidDate ?? this.paidDate,
      discount: discount ?? this.discount,
      amountPaid: amountPaid ?? this.amountPaid,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to calculate outstanding amount
  double getOutstandingAmount() {
    double outstanding = amount;

    // Subtract total discount applied
    if (discount != null) {
      outstanding -= discount!;
    }

    // Subtract total amount paid so far
    if (amountPaid != null) {
      outstanding -= amountPaid!;
    }

    // Ensure we don't return a negative value
    return outstanding > 0 ? outstanding : 0;
  }

// ADD this helper method to Payment class
  bool isFullyPaid() {
    return getOutstandingAmount() <= 0;
  }
}
