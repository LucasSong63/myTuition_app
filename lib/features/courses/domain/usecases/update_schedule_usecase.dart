// update_schedule_usecase.dart
import 'package:mytuition/features/notifications/domain/entities/notification_type.dart';
import 'package:mytuition/features/notifications/domain/notification_manager.dart';

import '../entities/schedule.dart';
import '../repositories/course_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class UpdateScheduleUseCase {
  final CourseRepository repository;
  NotificationManager? _notificationManager;

  UpdateScheduleUseCase(this.repository) {
    try {
      _notificationManager = GetIt.instance<NotificationManager>();
    } catch (e) {
      print('NotificationManager not available: $e');
    }
  }

  Future<void> execute(
      String courseId, String scheduleId, Schedule updatedSchedule) async {
    // Primary functionality
    await repository.updateSchedule(courseId, scheduleId, updatedSchedule);

    // Secondary functionality - notifications
    _sendScheduleUpdateNotifications(courseId, updatedSchedule);
  }

  Future<void> _sendScheduleUpdateNotifications(
      String courseId, Schedule schedule) async {
    if (_notificationManager == null) return;

    try {
      // Get students enrolled in this course
      final students = await repository.getEnrolledStudentsForCourse(courseId);
      if (students.isEmpty) return;

      // Get course details for better notification
      final courseDetails = await repository.getCourseDetailsById(courseId);
      final subject = courseDetails['subject'];
      final grade = courseDetails['grade'];

      final courseName = grade != null ? '$subject (Grade $grade)' : subject;

      // Format times for display
      final timeFormat = DateFormat('h:mm a');
      final startTimeStr = timeFormat.format(schedule.startTime);
      final endTimeStr = timeFormat.format(schedule.endTime);

      // Create notification content
      final title = "Class Schedule Updated";
      final message =
          "The class schedule for $courseName has been updated. New schedule: ${schedule.day} from $startTimeStr to $endTimeStr at ${schedule.location}";

      // Send to all enrolled students
      for (final studentId in students) {
        await _notificationManager!.sendStudentNotification(
          studentId: studentId,
          type: NotificationType.scheduleChange,
          title: title,
          message: message,
          data: {
            'courseId': courseId,
            'day': schedule.day,
            'startTime': schedule.startTime.millisecondsSinceEpoch,
            'endTime': schedule.endTime.millisecondsSinceEpoch,
            'location': schedule.location,
            'courseName': courseName,
          },
          createInApp: false,
        );
      }

      print(
          'Schedule update notifications sent to ${students.length} students');
    } catch (e) {
      print('Error sending schedule update notifications: $e');
    }
  }
}
