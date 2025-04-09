import '../entities/task.dart';
import '../entities/student_task.dart';

abstract class TaskRepository {
  // Get tasks for a specific course
  Future<List<Task>> getTasksByCourse(String courseId);

  // Get tasks for a student
  Future<List<Task>> getTasksForStudent(String studentId);

  // Get student-specific task details
  Future<StudentTask?> getStudentTask(String taskId, String studentId);

  // Create a new task for a course
  Future<Task> createTask(
      String courseId, String title, String description, DateTime? dueDate);

  // Update task details
  Future<void> updateTask(Task task);

  // Delete a task
  Future<void> deleteTask(String taskId);

  // Mark a task as completed for a student
  Future<void> markTaskAsCompleted(String taskId, String studentId,
      {String remarks = ''});

  // Mark a task as incomplete for a student
  Future<void> markTaskAsIncomplete(String taskId, String studentId);

  // Add remarks to a student's task
  Future<void> addTaskRemarks(String taskId, String studentId, String remarks);

  // Get all students' completion status for a task
  Future<List<StudentTask>> getTaskCompletionStatus(String taskId);
}
