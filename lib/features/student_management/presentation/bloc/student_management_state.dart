// Updated StudentManagementState class to better handle multiple loaded states
// This approach allows a single state to contain both enrolled and available courses

import 'package:equatable/equatable.dart';
import '../../domain/entities/student.dart';

abstract class StudentManagementState extends Equatable {
  const StudentManagementState();

  @override
  List<Object?> get props => [];
}

class StudentManagementInitial extends StudentManagementState {}

class StudentManagementLoading extends StudentManagementState {
  // Optional field to indicate what's being loaded
  final String? operation;

  const StudentManagementLoading({this.operation});

  @override
  List<Object?> get props => [operation];
}

class AllStudentsLoaded extends StudentManagementState {
  final List<Student> students;

  const AllStudentsLoaded({required this.students});

  @override
  List<Object?> get props => [students];
}

class StudentDetailsLoaded extends StudentManagementState {
  final Student student;

  // These fields can be null when not yet loaded
  final List<Map<String, dynamic>>? enrolledCourses;
  final List<Map<String, dynamic>>? availableCourses;

  const StudentDetailsLoaded({
    required this.student,
    this.enrolledCourses,
    this.availableCourses,
  });

  // Create a copy with updated fields
  StudentDetailsLoaded copyWith({
    Student? student,
    List<Map<String, dynamic>>? enrolledCourses,
    List<Map<String, dynamic>>? availableCourses,
  }) {
    return StudentDetailsLoaded(
      student: student ?? this.student,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      availableCourses: availableCourses ?? this.availableCourses,
    );
  }

  @override
  List<Object?> get props => [student, enrolledCourses, availableCourses];
}

// Keep these states for backward compatibility
class EnrolledCoursesLoaded extends StudentManagementState {
  final String studentId;
  final List<Map<String, dynamic>> enrolledCourses;

  const EnrolledCoursesLoaded({
    required this.studentId,
    required this.enrolledCourses,
  });

  @override
  List<Object?> get props => [studentId, enrolledCourses];
}

class AvailableCoursesLoaded extends StudentManagementState {
  final String studentId;
  final List<Map<String, dynamic>> availableCourses;

  const AvailableCoursesLoaded({
    required this.studentId,
    required this.availableCourses,
  });

  @override
  List<Object?> get props => [studentId, availableCourses];
}

class StudentManagementActionSuccess extends StudentManagementState {
  final String message;

  const StudentManagementActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class StudentManagementError extends StudentManagementState {
  final String message;

  const StudentManagementError({required this.message});

  @override
  List<Object?> get props => [message];
}
