// create_task_usecase.dart
import 'package:mytuition/features/notifications/domain/entities/notification_type.dart';
import 'package:mytuition/features/notifications/domain/notification_manager.dart';

import '../repositories/task_repository.dart';
import '../entities/task.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class CreateTaskUseCase {
  final TaskRepository repository;
  NotificationManager? _notificationManager;

  CreateTaskUseCase(this.repository) {
    try {
      _notificationManager = GetIt.instance<NotificationManager>();
    } catch (e) {
      print('NotificationManager not available: $e');
    }
  }

  Future<Task> execute(String courseId, String title, String description,
      DateTime? dueDate) async {
    // First create the task - primary functionality
    final task =
        await repository.createTask(courseId, title, description, dueDate);

    // Then send notifications - secondary functionality that shouldn't block task creation
    _sendNotifications(task, courseId, title, dueDate);

    return task;
  }

  // Separate method to handle notifications asynchronously without blocking
  Future<void> _sendNotifications(
      Task task, String courseId, String title, DateTime? dueDate) async {
    if (_notificationManager == null) return;

    try {
      // Get course details
      final students = await repository.getStudentsForCourse(courseId);
      final courseName = await repository.getCourseNameById(courseId);

      // Create a nice message with due date if available
      String message = "A new task '$title' has been assigned for $courseName";
      if (dueDate != null) {
        final formatter = DateFormat('EEE, MMM d, yyyy');
        message += " due on ${formatter.format(dueDate)}";
      }

      // Send to each enrolled student
      for (final studentId in students) {
        await _notificationManager!.sendStudentNotification(
          studentId: studentId,
          type: NotificationType.taskCreated,
          title: "New Task: $title",
          message: message,
          data: {
            'taskId': task.id,
            'courseId': courseId,
            'dueDate': dueDate?.millisecondsSinceEpoch,
            'courseName': courseName,
          },
        );
      }

      print('Task creation notifications sent to ${students.length} students');
    } catch (e) {
      // Log error but don't interrupt main flow
      print('Error sending task creation notifications: $e');
    }
  }
}
