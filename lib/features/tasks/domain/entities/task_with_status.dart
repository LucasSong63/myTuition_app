import 'package:equatable/equatable.dart';
import 'task.dart';

/// Enriched task entity that includes student-specific status information
/// This combines data from the tasks collection and student_tasks collection
class TaskWithStatus extends Equatable {
  final Task task;
  final bool isCompleted;
  final bool hasRemarks;
  final String remarks;
  final DateTime? completedAt;

  const TaskWithStatus({
    required this.task,
    this.isCompleted = false,
    this.hasRemarks = false,
    this.remarks = '',
    this.completedAt,
  });

  // Convenience getters to access task properties directly
  String get id => task.id;

  String get courseId => task.courseId;

  String get title => task.title;

  String get description => task.description;

  DateTime get createdAt => task.createdAt;

  DateTime? get dueDate => task.dueDate;

  // Check if a task is overdue (due date is in the past and task is not completed)
  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;

  @override
  List<Object?> get props => [
        task,
        isCompleted,
        hasRemarks,
        remarks,
        completedAt,
      ];
}
