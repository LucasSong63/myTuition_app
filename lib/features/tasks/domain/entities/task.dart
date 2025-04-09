// lib/features/tasks/domain/entities/task.dart
import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isCompleted;

  const Task({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.createdAt,
    this.dueDate,
    this.isCompleted = false,
  });

  @override
  List<Object?> get props => [
        id,
        courseId,
        title,
        description,
        createdAt,
        dueDate,
        isCompleted,
      ];
}
