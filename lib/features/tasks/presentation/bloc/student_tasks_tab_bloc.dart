// // BLoC implementation
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:mytuition/features/tasks/domain/usecases/get_student_tasks_tab_usecase.dart';
// import 'package:mytuition/features/tasks/presentation/bloc/student_tasks_tab_event.dart';
// import 'package:mytuition/features/tasks/presentation/bloc/student_tasks_tab_state.dart';
//
// class StudentTasksTabBloc
//     extends Bloc<StudentTasksTabEvent, StudentTasksTabState> {
//   final GetStudentTasksTabUseCase getStudentTasksTabUseCase;
//
//   StudentTasksTabBloc({required this.getStudentTasksTabUseCase})
//       : super(StudentTasksTabInitial()) {
//     on<LoadStudentTasksTabEvent>(_onLoadStudentTasks);
//     on<FilterStudentTasksEvent>(_onFilterStudentTasks);
//   }
//
//   Future<void> _onLoadStudentTasks(
//     LoadStudentTasksTabEvent event,
//     Emitter<StudentTasksTabState> emit,
//   ) async {
//     emit(StudentTasksTabLoading());
//     try {
//       print('Loading student tasks tab for studentId: ${event.studentId}');
//       final tasks = await getStudentTasksTabUseCase.execute(event.studentId);
//       print('Loaded ${tasks.length} tasks for student tasks tab');
//
//       // Sort tasks: overdue first, then pending by due date, then completed
//       tasks.sort((a, b) {
//         // First sort by completion status
//         if (a.isCompleted != b.isCompleted) {
//           return a.isCompleted ? 1 : -1; // Pending tasks first
//         }
//
//         // For tasks with the same completion status
//         if (!a.isCompleted) {
//           // Both pending
//           // If one is overdue and the other isn't
//           if (a.isOverdue != b.isOverdue) {
//             return a.isOverdue ? -1 : 1; // Overdue tasks first
//           }
//
//           // Sort by due date (earliest first)
//           if (a.dueDate != null && b.dueDate != null) {
//             return a.dueDate!.compareTo(b.dueDate!);
//           } else if (a.dueDate != null) {
//             return -1; // a has due date, b doesn't
//           } else if (b.dueDate != null) {
//             return 1; // b has due date, a doesn't
//           }
//         } else {
//           // Both completed
//           // Sort by completion date (most recent first)
//           if (a.completedAt != null && b.completedAt != null) {
//             return b.completedAt!.compareTo(a.completedAt!);
//           } else if (a.completedAt != null) {
//             return -1;
//           } else if (b.completedAt != null) {
//             return 1;
//           }
//         }
//
//         // Finally, sort by creation date
//         return b.createdAt.compareTo(a.createdAt);
//       });
//
//       emit(StudentTasksTabLoaded(tasks: tasks));
//     } catch (e) {
//       print('Error loading student tasks tab: $e');
//       emit(StudentTasksTabError(message: e.toString()));
//     }
//   }
//
//   void _onFilterStudentTasks(
//     FilterStudentTasksEvent event,
//     Emitter<StudentTasksTabState> emit,
//   ) {
//     if (state is StudentTasksTabLoaded) {
//       final currentState = state as StudentTasksTabLoaded;
//       emit(currentState.copyWith(filter: event.filter));
//     }
//   }
// }
