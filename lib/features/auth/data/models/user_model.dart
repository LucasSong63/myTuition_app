import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required String id,
    required String email,
    required String name,
    required String role,
    int? grade,
    List<String>? subjects,
    String? studentId,
    String? phone,
    String? profilePictureUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          docId: id,
          email: email,
          name: name,
          role: role,
          grade: grade,
          subjects: subjects,
          studentId: studentId,
          phone: phone,
          profilePictureUrl: profilePictureUrl,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  // Create a user model from a map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Handle Firestore timestamps
    DateTime? createdAt;
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is DateTime) {
      createdAt = map['createdAt'] as DateTime;
    } else {
      createdAt = DateTime.now();
    }

    DateTime? updatedAt;
    if (map['updatedAt'] is Timestamp) {
      updatedAt = (map['updatedAt'] as Timestamp).toDate();
    } else if (map['updatedAt'] is DateTime) {
      updatedAt = map['updatedAt'] as DateTime;
    } else {
      updatedAt = DateTime.now();
    }

    // Handle optional subjects field
    List<String>? subjects;
    if (map['subjects'] != null) {
      subjects = List<String>.from(map['subjects']);
    }

    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'student',
      grade: map['grade'],
      subjects: subjects,
      studentId: map['studentId'],
      phone: map['phone'],
      profilePictureUrl: map['profilePictureUrl'],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Convert the user model to a map
  Map<String, dynamic> toMap() {
    return {
      'id': docId,
      'email': email,
      'name': name,
      'role': role,
      'grade': grade,
      'subjects': subjects,
      'studentId': studentId,
      'phone': phone,
      'profilePictureUrl': profilePictureUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
