import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/student_task.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TasksLoaded extends TaskState {
  final List<Task> tasks;

  const TasksLoaded({required this.tasks});

  @override
  List<Object?> get props => [tasks];
}

class StudentTaskLoaded extends TaskState {
  final StudentTask? studentTask;
  final Task task;

  const StudentTaskLoaded({
    required this.task,
    this.studentTask,
  });

  @override
  List<Object?> get props => [task, studentTask];
}

class TaskCompletionStatusLoaded extends TaskState {
  final List<StudentTask> studentTasks;

  const TaskCompletionStatusLoaded({required this.studentTasks});

  @override
  List<Object?> get props => [studentTasks];
}

class TaskActionSuccess extends TaskState {
  final String message;

  const TaskActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class TaskError extends TaskState {
  final String message;

  const TaskError({required this.message});

  @override
  List<Object?> get props => [message];
}
