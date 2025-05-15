import 'package:equatable/equatable.dart';

class Student extends Equatable {
  final String documentId;
  final String name;
  final String email;
  final String studentId;
  final int grade;
  final String? phone;
  final String? profilePictureUrl;
  final List<String>? subjects;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Student({
    required this.documentId,
    required this.name,
    required this.email,
    required this.studentId,
    required this.grade,
    this.phone,
    this.profilePictureUrl,
    this.subjects,
    required this.emailVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        documentId,
        name,
        email,
        studentId,
        grade,
        phone,
        profilePictureUrl,
        subjects,
        emailVerified,
        createdAt,
        updatedAt,
      ];

  // Factory method to create a Student from a map
  factory Student.fromMap(Map<String, dynamic> map, String docId) {
    // Handle Firestore timestamps for createdAt
    DateTime createdAt;
    if (map['createdAt'] is DateTime) {
      createdAt = map['createdAt'];
    } else if (map['createdAt'] != null) {
      createdAt = (map['createdAt'] as dynamic).toDate();
    } else {
      createdAt = DateTime.now();
    }

    // Handle Firestore timestamps for updatedAt
    DateTime updatedAt;
    if (map['updatedAt'] is DateTime) {
      updatedAt = map['updatedAt'];
    } else if (map['updatedAt'] != null) {
      updatedAt = (map['updatedAt'] as dynamic).toDate();
    } else {
      updatedAt = DateTime.now();
    }

    // Convert subjects to List<String> if present
    List<String>? subjects;
    if (map['subjects'] != null) {
      subjects = List<String>.from(map['subjects']);
    }

    return Student(
      documentId: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      studentId: map['studentId'] ?? '',
      grade: map['grade'] ?? 0,
      phone: map['phone'],
      profilePictureUrl: map['profilePictureUrl'],
      subjects: subjects,
      emailVerified: map['emailVerified'] ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
