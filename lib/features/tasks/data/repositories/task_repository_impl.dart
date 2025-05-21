import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/student_task.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_model.dart';
import '../models/student_task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final FirebaseFirestore _firestore;

  TaskRepositoryImpl(this._firestore);

  @override
  Future<List<Task>> getTasksByCourse(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('courseId', isEqualTo: courseId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get tasks: $e');
    }
  }

  @override
  Future<List<Task>> getTasksForStudent(String studentId) async {
    try {
      // Get courses the student is enrolled in
      final courseSnapshot = await _firestore
          .collection('classes')
          .where('students', arrayContains: studentId)
          .get();

      final courseIds = courseSnapshot.docs.map((doc) => doc.id).toList();

      // No courses found
      if (courseIds.isEmpty) {
        return [];
      }

      // Get tasks for these courses
      final taskSnapshot = await _firestore
          .collection('tasks')
          .where('courseId', whereIn: courseIds)
          .orderBy('createdAt', descending: true)
          .get();

      return taskSnapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get student tasks: $e');
    }
  }

  @override
  Future<Task?> getTaskById(String taskId) async {
    try {
      final docSnapshot =
          await _firestore.collection('tasks').doc(taskId).get();
      if (!docSnapshot.exists) {
        return null;
      }
      return TaskModel.fromMap(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      print('Error getting task by ID: $e');
      throw Exception('Failed to get task: $e');
    }
  }

  @override
  Future<StudentTask?> getStudentTask(String taskId, String studentId) async {
    try {
      final studentTaskId = '$taskId-$studentId';
      print('Looking for student task with ID: $studentTaskId');

      final docSnapshot =
          await _firestore.collection('student_tasks').doc(studentTaskId).get();

      if (!docSnapshot.exists) {
        print('No existing student task found, returning null');
        return null;
      }

      return StudentTaskModel.fromMap(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      print('Error getting student task: $e');
      throw Exception('Failed to get student task: $e');
    }
  }

  @override
  Future<Task> createTask(String courseId, String title, String description,
      DateTime? dueDate) async {
    try {
      final task = {
        'courseId': courseId,
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'dueDate': dueDate,
        'isCompleted': false,
      };

      final docRef = await _firestore.collection('tasks').add(task);
      final doc = await docRef.get();

      return TaskModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  @override
  Future<void> updateTask(Task task) async {
    try {
      final taskModel = task as TaskModel;
      await _firestore
          .collection('tasks')
          .doc(task.id)
          .update(taskModel.toMap());
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      // Delete task document
      await _firestore.collection('tasks').doc(taskId).delete();

      // Delete all student task records for this task
      final studentTasksSnapshot = await _firestore
          .collection('student_tasks')
          .where('taskId', isEqualTo: taskId)
          .get();

      final batch = _firestore.batch();
      for (var doc in studentTasksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  @override
  Future<void> markTaskAsCompleted(String taskId, String studentId,
      {String remarks = ''}) async {
    try {
      final docId = '$taskId-$studentId';
      final now = DateTime.now();

      await _firestore.collection('student_tasks').doc(docId).set({
        'taskId': taskId,
        'studentId': studentId,
        'remarks': remarks,
        'isCompleted': true,
        'completedAt': now,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to mark task as completed: $e');
    }
  }

  @override
  Future<void> markTaskAsIncomplete(String taskId, String studentId) async {
    try {
      final docId = '$taskId-$studentId';

      await _firestore.collection('student_tasks').doc(docId).set({
        'taskId': taskId,
        'studentId': studentId,
        'isCompleted': false,
        'completedAt': null,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to mark task as incomplete: $e');
    }
  }

  @override
  Future<void> addTaskRemarks(
      String taskId, String studentId, String remarks) async {
    try {
      final docId = '$taskId-$studentId';

      await _firestore.collection('student_tasks').doc(docId).set({
        'taskId': taskId,
        'studentId': studentId,
        'remarks': remarks,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add task remarks: $e');
    }
  }

  @override
  Future<List<StudentTask>> getTaskCompletionStatus(String taskId) async {
    try {
      // Get task details to find the course ID
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        throw Exception('Task not found');
      }

      final String courseId = taskDoc.data()?['courseId'] ?? '';

      // Get all students enrolled in this course
      final courseDoc =
          await _firestore.collection('classes').doc(courseId).get();
      final List<dynamic> enrolledStudentsRaw =
          courseDoc.data()?['students'] ?? [];
      final List<String> enrolledStudents =
          enrolledStudentsRaw.map((s) => s.toString()).toList();

      print(
          'Found ${enrolledStudents.length} students enrolled in course: $courseId');
      for (var student in enrolledStudents) {
        print('Student ID: $student');
      }

      if (enrolledStudents.isEmpty) {
        print('No students enrolled in course: $courseId');
        return []; // No students enrolled
      }

      // Get existing student tasks
      final snapshot = await _firestore
          .collection('student_tasks')
          .where('taskId', isEqualTo: taskId)
          .get();

      List<StudentTask> studentTasks = snapshot.docs
          .map((doc) => StudentTaskModel.fromMap(doc.data(), doc.id))
          .toList();

      print(
          'Found ${studentTasks.length} existing student tasks for task: $taskId');

      // Create a map of existing student tasks for quick lookup
      final Map<String, StudentTask> existingTasksMap = {
        for (var task in studentTasks) task.studentId: task
      };

      // Create placeholder tasks for students who don't have one yet
      List<StudentTask> allStudentTasks = [];

      for (String studentId in enrolledStudents) {
        if (existingTasksMap.containsKey(studentId)) {
          // Use existing task
          allStudentTasks.add(existingTasksMap[studentId]!);
          print('Using existing task for student: $studentId');
        } else {
          // Create a placeholder task
          final studentTask = StudentTaskModel(
            id: '$taskId-$studentId',
            taskId: taskId,
            studentId: studentId,
            remarks: '',
            isCompleted: false,
          );
          allStudentTasks.add(studentTask);
          print('Created placeholder task for student: $studentId');

          // Optionally save this placeholder to Firestore
          // Uncomment to persist these placeholder tasks
          /*
          await _firestore.collection('student_tasks').doc('$taskId-$studentId').set({
            'taskId': taskId,
            'studentId': studentId,
            'remarks': '',
            'isCompleted': false,
            'completedAt': null,
          });
          */
        }
      }

      print('Returning ${allStudentTasks.length} student tasks');
      return allStudentTasks;
    } catch (e) {
      print('Error getting task completion status: $e');
      throw Exception('Failed to get task completion status: $e');
    }
  }

  @override
  Future<List<String>> getStudentsForCourse(String courseId) async {
    try {
      final courseDoc =
          await _firestore.collection('classes').doc(courseId).get();

      if (!courseDoc.exists) {
        return [];
      }

      final List<dynamic> enrolledStudentsRaw =
          courseDoc.data()?['students'] ?? [];
      return enrolledStudentsRaw.map((s) => s.toString()).toList();
    } catch (e) {
      print('Error getting students for course: $e');
      return []; // Return empty list instead of throwing to prevent cascading failures
    }
  }

  @override
  Future<String> getCourseNameById(String courseId) async {
    try {
      final courseDoc =
          await _firestore.collection('classes').doc(courseId).get();

      if (!courseDoc.exists) {
        return 'Unknown Course';
      }

      final String subject = courseDoc.data()?['subject'] ?? 'Unknown Subject';
      final dynamic grade = courseDoc.data()?['grade'];

      return grade != null ? '$subject (Grade $grade)' : subject;
    } catch (e) {
      print('Error getting course name: $e');
      return 'Unknown Course'; // Return a fallback instead of throwing
    }
  }
}
