// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:mytuition/features/tasks/data/models/student_task_model.dart';
// import 'package:mytuition/features/tasks/data/models/task_model.dart';
// import 'package:mytuition/features/tasks/data/repositories/task_repository_impl.dart';
// import '../../domain/entities/task.dart';
// import '../../domain/entities/student_task.dart';
// import '../../domain/repositories/task_repository.dart';
//
// // Extension methods for the TaskRepositoryImpl class that you can add
// // without modifying your existing implementation
//
// extension TaskRepositoryStudentTasksTab on TaskRepositoryImpl {
//   /// Get all student tasks for a specific student
//   /// This is specifically for the student tasks tab feature
//   Future<List<StudentTask>> getStudentTasksForStudent(String studentId) async {
//     try {
//       print('Fetching student tasks for student ID: $studentId');
//
//       final snapshot = await _firestore
//           .collection('student_tasks')
//           .where('studentId', isEqualTo: studentId)
//           .get();
//
//       print('Found ${snapshot.docs.length} student task records');
//
//       return snapshot.docs
//           .map((doc) => StudentTaskModel.fromMap(doc.data(), doc.id))
//           .toList();
//     } catch (e) {
//       print('Error fetching student tasks: $e');
//       throw Exception('Failed to get student tasks: $e');
//     }
//   }
//
//   /// Optimized method for the student tasks tab that fetches all
//   /// necessary data in a single method call
//   Future<Map<String, dynamic>> getStudentTasksTabData(String studentId) async {
//     try {
//       print('Fetching all data for student tasks tab: $studentId');
//
//       // 1. Get courses the student is enrolled in
//       final courseSnapshot = await _firestore
//           .collection('classes')
//           .where('students', arrayContains: studentId)
//           .get();
//
//       print('Found ${courseSnapshot.docs.length} courses');
//       final courseIds = courseSnapshot.docs.map((doc) => doc.id).toList();
//
//       // Create a map of courseId -> course name for easier access
//       final Map<String, String> courseNames = {};
//       for (var doc in courseSnapshot.docs) {
//         final data = doc.data();
//         final courseId = doc.id;
//         final subject = data['subject'] as String? ?? 'Unknown Subject';
//         final grade = data['grade'] as int? ?? 0;
//         courseNames[courseId] = '$subject Grade $grade';
//       }
//
//       // No courses found
//       if (courseIds.isEmpty) {
//         print('No courses found');
//         return {
//           'tasks': <Task>[],
//           'studentTasks': <StudentTask>[],
//           'courseNames': <String, String>{},
//         };
//       }
//
//       // 2. Get all tasks for these courses
//       List<Task> allTasks = [];
//       // Process in batches of 10 due to Firestore limitations
//       for (int i = 0; i < courseIds.length; i += 10) {
//         final endIdx = (i + 10 < courseIds.length) ? i + 10 : courseIds.length;
//         final batchCourseIds = courseIds.sublist(i, endIdx);
//
//         final taskSnapshot = await _firestore
//             .collection('tasks')
//             .where('courseId', whereIn: batchCourseIds)
//             .get();
//
//         final batchTasks = taskSnapshot.docs
//             .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
//             .toList();
//
//         allTasks.addAll(batchTasks);
//       }
//       print('Found ${allTasks.length} total tasks');
//
//       // 3. Get student_task entries
//       final studentTasksSnapshot = await _firestore
//           .collection('student_tasks')
//           .where('studentId', isEqualTo: studentId)
//           .get();
//
//       final studentTasks = studentTasksSnapshot.docs
//           .map((doc) => StudentTaskModel.fromMap(doc.data(), doc.id))
//           .toList();
//
//       print('Found ${studentTasks.length} student task records');
//
//       // Return everything in a single map
//       return {
//         'tasks': allTasks,
//         'studentTasks': studentTasks,
//         'courseNames': courseNames,
//       };
//     } catch (e) {
//       print('Error fetching student tasks tab data: $e');
//       throw Exception('Failed to load student tasks tab data: $e');
//     }
//   }
// }
