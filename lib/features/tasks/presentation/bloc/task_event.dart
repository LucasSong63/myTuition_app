import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasksByCourseEvent extends TaskEvent {
  final String courseId;

  const LoadTasksByCourseEvent({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

class LoadTasksForStudentEvent extends TaskEvent {
  final String studentId;

  const LoadTasksForStudentEvent({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

class LoadStudentTaskEvent extends TaskEvent {
  final String taskId;
  final String studentId;

  const LoadStudentTaskEvent({
    required this.taskId,
    required this.studentId,
  });

  @override
  List<Object?> get props => [taskId, studentId];
}

class CreateTaskEvent extends TaskEvent {
  final String courseId;
  final String title;
  final String description;
  final DateTime? dueDate;

  const CreateTaskEvent({
    required this.courseId,
    required this.title,
    required this.description,
    this.dueDate,
  });

  @override
  List<Object?> get props => [courseId, title, description, dueDate];
}

class UpdateTaskEvent extends TaskEvent {
  final Task task;

  const UpdateTaskEvent({required this.task});

  @override
  List<Object?> get props => [task];
}

class DeleteTaskEvent extends TaskEvent {
  final String taskId;
  final String courseId; // Add courseId parameter

  const DeleteTaskEvent({
    required this.taskId,
    required this.courseId, // Make it required
  });

  @override
  List<Object?> get props => [taskId, courseId];
}

class MarkTaskAsCompletedEvent extends TaskEvent {
  final String taskId;
  final String studentId;
  final String remarks;

  const MarkTaskAsCompletedEvent({
    required this.taskId,
    required this.studentId,
    this.remarks = '',
  });

  @override
  List<Object?> get props => [taskId, studentId, remarks];
}

class MarkTaskAsIncompleteEvent extends TaskEvent {
  final String taskId;
  final String studentId;

  const MarkTaskAsIncompleteEvent({
    required this.taskId,
    required this.studentId,
  });

  @override
  List<Object?> get props => [taskId, studentId];
}

class AddTaskRemarksEvent extends TaskEvent {
  final String taskId;
  final String studentId;
  final String remarks;

  const AddTaskRemarksEvent({
    required this.taskId,
    required this.studentId,
    required this.remarks,
  });

  @override
  List<Object?> get props => [taskId, studentId, remarks];
}

class LoadTaskCompletionStatusEvent extends TaskEvent {
  final String taskId;

  const LoadTaskCompletionStatusEvent({required this.taskId});

  @override
  List<Object?> get props => [taskId];
}
