// lib/features/attendance/domain/utils/schedule_date_utils.dart
import 'package:mytuition/features/courses/domain/entities/schedule.dart';
import 'package:intl/intl.dart';

class ScheduleDateUtils {
  /// Find the date for a weekly schedule in the current week
  /// For example: If today is Wednesday and schedule is for "Monday",
  /// return the Monday of this week
  static DateTime getScheduleDateForCurrentWeek(Schedule schedule,
      {DateTime? referenceDate}) {
    final reference = referenceDate ?? DateTime.now();

    if (schedule.type == ScheduleType.replacement &&
        schedule.specificDate != null) {
      // Replacement schedules have specific dates
      return DateTime(
        schedule.specificDate!.year,
        schedule.specificDate!.month,
        schedule.specificDate!.day,
      );
    }

    // For regular schedules, find the date in current week
    final targetWeekday = _getWeekdayFromDayName(schedule.day);
    final currentWeekday = reference.weekday;

    // Calculate days difference
    final daysDifference = targetWeekday - currentWeekday;

    final targetDate = reference.add(Duration(days: daysDifference));
    return DateTime(targetDate.year, targetDate.month, targetDate.day);
  }

  /// Get weekday number from day name (Monday = 1, Sunday = 7)
  static int _getWeekdayFromDayName(String dayName) {
    const dayMap = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
    return dayMap[dayName.toLowerCase()] ?? 1;
  }

  /// Check if a schedule date is in the past (for validation)
  static bool isScheduleDateInPast(Schedule schedule,
      {DateTime? referenceDate}) {
    final scheduleDate =
        getScheduleDateForCurrentWeek(schedule, referenceDate: referenceDate);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return scheduleDate.isBefore(todayOnly);
  }

  /// Get user-friendly date display for schedule
  static String getScheduleDateDisplay(Schedule schedule,
      {DateTime? referenceDate}) {
    final date =
        getScheduleDateForCurrentWeek(schedule, referenceDate: referenceDate);
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Get short date display (e.g., "Jun 12")
  static String getScheduleDateShort(Schedule schedule,
      {DateTime? referenceDate}) {
    final date =
        getScheduleDateForCurrentWeek(schedule, referenceDate: referenceDate);
    return DateFormat('MMM d').format(date);
  }

  /// Format time range display (e.g., "9:00 AM - 1:00 PM")
  static String formatTimeRange(DateTime startTime, DateTime endTime) {
    final start = DateFormat('h:mm a').format(startTime);
    final end = DateFormat('h:mm a').format(endTime);
    return '$start - $end';
  }

  /// Calculate duration between start and end time
  static String formatDuration(DateTime startTime, DateTime endTime) {
    final duration = endTime.difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Check if schedule is today
  static bool isScheduleToday(Schedule schedule) {
    final scheduleDate = getScheduleDateForCurrentWeek(schedule);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return scheduleDate.isAtSameMomentAs(todayOnly);
  }

  /// Check if schedule is in the future
  static bool isScheduleInFuture(Schedule schedule) {
    final scheduleDate = getScheduleDateForCurrentWeek(schedule);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return scheduleDate.isAfter(todayOnly);
  }

  /// Get relative date description (e.g., "Today", "Tomorrow", "Monday")
  static String getRelativeDateDescription(Schedule schedule) {
    final scheduleDate = getScheduleDateForCurrentWeek(schedule);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final difference = scheduleDate.difference(todayOnly).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 1 && difference <= 7) {
      return DateFormat('EEEE').format(scheduleDate); // Day name
    } else {
      return DateFormat('MMM d').format(scheduleDate); // Month day
    }
  }
}
