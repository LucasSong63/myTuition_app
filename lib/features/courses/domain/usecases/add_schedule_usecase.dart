// add_schedule_usecase.dart
import 'package:mytuition/features/notifications/domain/entities/notification_type.dart';
import 'package:mytuition/features/notifications/domain/notification_manager.dart';

import '../entities/schedule.dart';
import '../repositories/course_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class AddScheduleUseCase {
  final CourseRepository repository;
  NotificationManager? _notificationManager;

  AddScheduleUseCase(this.repository) {
    try {
      _notificationManager = GetIt.instance<NotificationManager>();
    } catch (e) {
      print('NotificationManager not available: $e');
    }
  }

  Future<void> execute(String courseId, Schedule schedule) async {
    // Primary functionality
    await repository.addSchedule(courseId, schedule);

    // Secondary functionality - notifications
    _sendScheduleNotifications(courseId, schedule);
  }

  Future<void> _sendScheduleNotifications(
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
      final title = "New Class Schedule";
      final message =
          "A new class schedule has been added for $courseName on ${schedule.day} from $startTimeStr to $endTimeStr at ${schedule.location}";

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
          'Schedule addition notifications sent to ${students.length} students');
    } catch (e) {
      print('Error sending schedule notifications: $e');
    }
  }
}
