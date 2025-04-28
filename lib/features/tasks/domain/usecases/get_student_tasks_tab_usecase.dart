// import '../repositories/task_repository.dart';
// import '../entities/task.dart';
// import '../entities/student_task.dart';
//
// /// A specialized use case for the Student Tasks tab
// /// This is separate from the existing GetTasksForStudentUseCase to avoid conflicts
// class GetStudentTasksTabUseCase {
//   final TaskRepository repository;
//
//   GetStudentTasksTabUseCase(this.repository);
//
//   /// Fetches all tasks for the student tasks tab, including completion status
//   Future<List<TaskWithStudentData>> execute(String studentId) async {
//     try {
//       print('Fetching tasks for student tasks tab: $studentId');
//
//       // 1. Get all tasks from courses the student is enrolled in
//       final tasks = await repository.getTasksForStudent(studentId);
//       print('Found ${tasks.length} tasks for student');
//
//       // 2. Get all student task records for this student
//       final studentTasksSnapshot =
//           await repository.getStudentTasksForStudent(studentId);
//       print('Found ${studentTasksSnapshot.length} student task records');
//
//       // 3. Create a map of taskId -> studentTask for quick lookup
//       final Map<String, StudentTask> studentTaskMap = {};
//       for (var studentTask in studentTasksSnapshot) {
//         studentTaskMap[studentTask.taskId] = studentTask;
//       }
//
//       // 4. Combine the data into a specialized class for the UI
//       final enrichedTasks = tasks.map((task) {
//         final hasStudentTask = studentTaskMap.containsKey(task.id);
//         final isCompleted =
//             hasStudentTask ? studentTaskMap[task.id]!.isCompleted : false;
//         final hasRemarks =
//             hasStudentTask && studentTaskMap[task.id]!.remarks.isNotEmpty;
//         final completedAt =
//             hasStudentTask ? studentTaskMap[task.id]!.completedAt : null;
//
//         return TaskWithStudentData(
//           task: task,
//           isCompleted: isCompleted,
//           hasRemarks: hasRemarks,
//           completedAt: completedAt,
//         );
//       }).toList();
//
//       print(
//           'Returning ${enrichedTasks.length} enriched tasks for the student tasks tab');
//       return enrichedTasks;
//     } catch (e) {
//       print('Error in GetStudentTasksTabUseCase: $e');
//       throw Exception('Failed to get tasks for student tasks tab: $e');
//     }
//   }
// }
//
// /// A specialized class that combines a Task with student-specific data
// /// This is used for the student tasks tab display
// class TaskWithStudentData {
//   final Task task;
//   final bool isCompleted;
//   final bool hasRemarks;
//   final DateTime? completedAt;
//
//   TaskWithStudentData({
//     required this.task,
//     this.isCompleted = false,
//     this.hasRemarks = false,
//     this.completedAt,
//   });
//
//   // Convenience getters to access task properties directly
//   String get id => task.id;
//
//   String get courseId => task.courseId;
//
//   String get title => task.title;
//
//   String get description => task.description;
//
//   DateTime get createdAt => task.createdAt;
//
//   DateTime? get dueDate => task.dueDate;
//
//   // Check if a task is overdue (due date is in the past and task is not completed)
//   bool get isOverdue =>
//       dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;
// }
