import 'package:equatable/equatable.dart';

abstract class StudentManagementEvent extends Equatable {
  const StudentManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllStudentsEvent extends StudentManagementEvent {}

class LoadStudentDetailsEvent extends StudentManagementEvent {
  final String studentId;

  const LoadStudentDetailsEvent({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

class LoadEnrolledCoursesEvent extends StudentManagementEvent {
  final String studentId;

  const LoadEnrolledCoursesEvent({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

class LoadAvailableCoursesEvent extends StudentManagementEvent {
  final String studentId;

  const LoadAvailableCoursesEvent({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

class EnrollStudentEvent extends StudentManagementEvent {
  final String studentId;
  final String courseId;

  const EnrollStudentEvent({
    required this.studentId,
    required this.courseId,
  });

  @override
  List<Object?> get props => [studentId, courseId];
}

class RemoveStudentFromCourseEvent extends StudentManagementEvent {
  final String studentId;
  final String courseId;

  const RemoveStudentFromCourseEvent({
    required this.studentId,
    required this.courseId,
  });

  @override
  List<Object?> get props => [studentId, courseId];
}

class UpdateStudentProfileEvent extends StudentManagementEvent {
  final String userId;
  final String? name;
  final String? phone;
  final int? grade;
  final List<String>? subjects;

  const UpdateStudentProfileEvent({
    required this.userId,
    this.name,
    this.phone,
    this.grade,
    this.subjects,
  });

  @override
  List<Object?> get props => [userId, name, phone, grade, subjects];
}
