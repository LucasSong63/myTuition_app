// // State definitions
// import 'package:equatable/equatable.dart';
// import 'package:mytuition/features/tasks/domain/usecases/get_student_tasks_tab_usecase.dart';
// import 'package:mytuition/features/tasks/presentation/bloc/student_tasks_tab_event.dart';
//
// abstract class StudentTasksTabState extends Equatable {
//   const StudentTasksTabState();
//
//   @override
//   List<Object?> get props => [];
// }
//
// class StudentTasksTabInitial extends StudentTasksTabState {}
//
// class StudentTasksTabLoading extends StudentTasksTabState {}
//
// class StudentTasksTabLoaded extends StudentTasksTabState {
//   final List<TaskWithStudentData> tasks;
//   final StudentTasksFilter filter;
//
//   // Computed property for filtered tasks
//   List<TaskWithStudentData> get filteredTasks {
//     switch (filter) {
//       case StudentTasksFilter.all:
//         return tasks;
//       case StudentTasksFilter.pending:
//         return tasks.where((task) => !task.isCompleted).toList();
//       case StudentTasksFilter.completed:
//         return tasks.where((task) => task.isCompleted).toList();
//     }
//   }
//
//   const StudentTasksTabLoaded({
//     required this.tasks,
//     this.filter = StudentTasksFilter.all,
//   });
//
//   @override
//   List<Object?> get props => [tasks, filter];
//
//   StudentTasksTabLoaded copyWith({
//     List<TaskWithStudentData>? tasks,
//     StudentTasksFilter? filter,
//   }) {
//     return StudentTasksTabLoaded(
//       tasks: tasks ?? this.tasks,
//       filter: filter ?? this.filter,
//     );
//   }
// }
//
// class StudentTasksTabError extends StudentTasksTabState {
//   final String message;
//
//   const StudentTasksTabError({required this.message});
//
//   @override
//   List<Object?> get props => [message];
// }
