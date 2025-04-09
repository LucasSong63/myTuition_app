import 'package:equatable/equatable.dart';

class StudentTask extends Equatable {
  final String id;
  final String taskId;
  final String studentId;
  final String remarks;
  final bool isCompleted;
  final DateTime? completedAt;

  const StudentTask({
    required this.id,
    required this.taskId,
    required this.studentId,
    this.remarks = '',
    this.isCompleted = false,
    this.completedAt,
  });

  @override
  List<Object?> get props => [
        id,
        taskId,
        studentId,
        remarks,
        isCompleted,
        completedAt,
      ];
}
