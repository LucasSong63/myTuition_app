import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/get_student_tasks_tab_usecase.dart';

// Event definitions
abstract class StudentTasksTabEvent extends Equatable {
  const StudentTasksTabEvent();

  @override
  List<Object?> get props => [];
}

class LoadStudentTasksTabEvent extends StudentTasksTabEvent {
  final String studentId;

  const LoadStudentTasksTabEvent({required this.studentId});

  @override
  List<Object?> get props => [studentId];
}

class FilterStudentTasksEvent extends StudentTasksTabEvent {
  final StudentTasksFilter filter;

  const FilterStudentTasksEvent({required this.filter});

  @override
  List<Object?> get props => [filter];
}

// Filter enum
enum StudentTasksFilter { all, pending, completed }
