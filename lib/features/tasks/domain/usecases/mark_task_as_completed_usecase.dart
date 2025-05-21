// mark_task_as_completed_usecase.dart
import 'package:mytuition/features/notifications/domain/entities/notification_type.dart';
import 'package:mytuition/features/notifications/domain/notification_manager.dart';

import '../repositories/task_repository.dart';
import 'package:get_it/get_it.dart';

class MarkTaskAsCompletedUseCase {
  final TaskRepository repository;
  NotificationManager? _notificationManager;

  MarkTaskAsCompletedUseCase(this.repository) {
    try {
      _notificationManager = GetIt.instance<NotificationManager>();
    } catch (e) {
      print('NotificationManager not available: $e');
    }
  }

  Future<void> execute(String taskId, String studentId,
      {String remarks = ''}) async {
    // Main functionality first
    await repository.markTaskAsCompleted(taskId, studentId, remarks: remarks);

    // Then notifications
    _sendCompletionNotification(taskId, studentId);
  }

  Future<void> _sendCompletionNotification(
      String taskId, String studentId) async {
    if (_notificationManager == null) return;

    try {
      // Get task details
      final task = await repository.getTaskById(taskId);
      if (task == null) return;

      final courseName = await repository.getCourseNameById(task.courseId);

      // Send completion notification to student
      await _notificationManager!.sendStudentNotification(
        studentId: studentId,
        type: NotificationType.taskCompleted,
        title: "Task Completed",
        message:
            "You have completed the task '${task.title}' for $courseName. Well done!",
        data: {
          'taskId': taskId,
          'courseId': task.courseId,
        },
      );

      print('Task completion notification sent to student: $studentId');
    } catch (e) {
      print('Error sending task completion notification: $e');
    }
  }
}
