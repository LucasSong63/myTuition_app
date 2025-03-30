import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class RegistrationRequest extends Equatable {
  final String id;
  final String email;
  final String name;
  final String phone;
  final int grade;
  final List<String> subjects;
  final bool hasConsulted;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectReason;
  final DateTime createdAt;

  const RegistrationRequest({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.grade,
    required this.subjects,
    required this.hasConsulted,
    required this.status,
    this.rejectReason,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    phone,
    grade,
    subjects,
    hasConsulted,
    status,
    rejectReason,
    createdAt,
  ];

  // Create from Firestore document
  factory RegistrationRequest.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle Firestore timestamps
    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is DateTime) {
      createdAt = data['createdAt'] as DateTime;
    } else {
      createdAt = DateTime.now();
    }

    return RegistrationRequest(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      grade: data['grade'] ?? 1,
      subjects: List<String>.from(data['subjects'] ?? []),
      hasConsulted: data['hasConsulted'] ?? false,
      status: data['status'] ?? 'pending',
      rejectReason: data['rejectReason'],
      createdAt: createdAt,
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'grade': grade,
      'subjects': subjects,
      'hasConsulted': hasConsulted,
      'status': status,
      'rejectReason': rejectReason,
      'createdAt': createdAt,
    };
  }

  // Create a copy with modified fields
  RegistrationRequest copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    int? grade,
    List<String>? subjects,
    bool? hasConsulted,
    String? status,
    String? rejectReason,
    DateTime? createdAt,
  }) {
    return RegistrationRequest(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      grade: grade ?? this.grade,
      subjects: subjects ?? this.subjects,
      hasConsulted: hasConsulted ?? this.hasConsulted,
      status: status ?? this.status,
      rejectReason: rejectReason ?? this.rejectReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}