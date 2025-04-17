import 'package:equatable/equatable.dart';

enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
}

class Attendance extends Equatable {
  final String id;
  final String courseId;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Attendance({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.date,
    required this.status,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        courseId,
        studentId,
        date,
        status,
        remarks,
        createdAt,
        updatedAt,
      ];
}
