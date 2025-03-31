import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String role;
  final int? grade;
  final List<String>? subjects;
  final String? studentId;
  final String? phone;
  final String? profilePictureUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.grade,
    this.subjects,
    this.studentId,
    this.phone,
    this.profilePictureUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isStudent => role == 'student';

  bool get isTutor => role == 'tutor';

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        role,
        grade,
        subjects,
        studentId,
        phone,
        profilePictureUrl,
        createdAt,
        updatedAt,
      ];
}
