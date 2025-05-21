// add_task_remarks_usecase.dart
import 'package:mytuition/features/notifications/domain/entities/notification_type.dart';
import 'package:mytuition/features/notifications/domain/notification_manager.dart';

import '../repositories/task_repository.dart';
import 'package:get_it/get_it.dart';

class AddTaskRemarksUseCase {
  final TaskRepository repository;
  NotificationManager? _notificationManager;

  AddTaskRemarksUseCase(this.repository) {
    try {
      _notificationManager = GetIt.instance<NotificationManager>();
    } catch (e) {
      print('NotificationManager not available: $e');
    }
  }

  Future<void> execute(String taskId, String studentId, String remarks) async {
    // Primary functionality
    await repository.addTaskRemarks(taskId, studentId, remarks);

    // Secondary functionality (notifications)
    _sendRemarksNotification(taskId, studentId, remarks);
  }

  Future<void> _sendRemarksNotification(
      String taskId, String studentId, String remarks) async {
    if (_notificationManager == null) return;

    try {
      // Get task and course info for better notification
      final task = await repository.getTaskById(taskId);
      if (task == null) return;

      final courseName = await repository.getCourseNameById(task.courseId);

      // Create an appropriate message - shorter if remarks are long
      String remarksSummary = remarks;
      if (remarks.length > 50) {
        remarksSummary = remarks.substring(0, 47) + '...';
      }

      // Notify the student
      await _notificationManager!.sendStudentNotification(
        studentId: studentId,
        type: NotificationType.taskFeedback,
        title: "Feedback on Task: ${task.title}",
        message:
            "Your tutor has added feedback on your task for $courseName: \"$remarksSummary\"",
        data: {
          'taskId': taskId,
          'courseId': task.courseId,
          'remarks': remarks,
        },
      );

      print('Task remarks notification sent to student: $studentId');
    } catch (e) {
      print('Error sending task remarks notification: $e');
    }
  }
}
