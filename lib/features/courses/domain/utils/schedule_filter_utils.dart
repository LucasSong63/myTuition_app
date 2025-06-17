// lib/features/courses/domain/utils/schedule_filter_utils.dart
import '../entities/schedule.dart';

/// Utility class for filtering schedules based on various criteria
class ScheduleFilterUtils {
  /// Filter out expired replacement schedules and inactive schedules
  static List<Schedule> getActiveSchedules(List<Schedule> allSchedules) {
    final now = DateTime.now();
    return allSchedules.where((schedule) {
      // Must be active
      if (!schedule.isActive) return false;

      // Keep all regular schedules
      if (schedule.isRegular) return true;

      // For replacement schedules, check if they're not expired
      if (schedule.isReplacement) {
        return !schedule.isExpired;
      }

      // For extension schedules, check if they're relevant for today or future
      if (schedule.isExtension) {
        if (schedule.specificDate != null) {
          final scheduleDate = DateTime(
            schedule.specificDate!.year,
            schedule.specificDate!.month,
            schedule.specificDate!.day,
          );
          final today = DateTime(now.year, now.month, now.day);
          return scheduleDate.isAfter(today) ||
              scheduleDate.isAtSameMomentAs(today);
        }
        return true; // Keep extension without specific date
      }

      // Keep cancelled schedules for record keeping but mark them clearly
      return schedule.type != ScheduleType.cancelled;
    }).toList();
  }

  /// Get schedules available for attendance taking (excludes cancelled)
  static List<Schedule> getAttendanceEligibleSchedules(
      List<Schedule> allSchedules) {
    return getActiveSchedules(allSchedules).where((schedule) {
      return schedule.type != ScheduleType.cancelled;
    }).toList();
  }

  /// Get today's relevant schedules
  static List<Schedule> getTodaysSchedules(List<Schedule> allSchedules) {
    final today = DateTime.now();
    final todayWeekday = today.weekday;
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final todayName = weekdays[todayWeekday - 1];

    return getActiveSchedules(allSchedules).where((schedule) {
      if (schedule.isReplacement) {
        // Check if replacement is for today
        if (schedule.specificDate != null) {
          final scheduleDate = DateTime(
            schedule.specificDate!.year,
            schedule.specificDate!.month,
            schedule.specificDate!.day,
          );
          final todayDate = DateTime(today.year, today.month, today.day);
          return scheduleDate.isAtSameMomentAs(todayDate);
        }
        return false;
      }

      // Regular schedules - check day match
      return schedule.day.toLowerCase() == todayName.toLowerCase();
    }).toList();
  }

  /// Get upcoming schedules within next 7 days
  static List<Schedule> getUpcomingSchedules(List<Schedule> allSchedules,
      {int daysAhead = 7}) {
    final today = DateTime.now();
    final upcomingSchedules = <Schedule>[];

    for (int i = 0; i <= daysAhead; i++) {
      final targetDate = today.add(Duration(days: i));
      final daySchedules = getSchedulesForDate(allSchedules, targetDate);
      upcomingSchedules.addAll(daySchedules);
    }

    return upcomingSchedules;
  }

  /// Get schedules for a specific date
  static List<Schedule> getSchedulesForDate(
      List<Schedule> allSchedules, DateTime date) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = weekdays[date.weekday - 1];

    return getActiveSchedules(allSchedules).where((schedule) {
      if (schedule.isReplacement) {
        // Check if replacement is for this specific date
        if (schedule.specificDate != null) {
          final scheduleDate = DateTime(
            schedule.specificDate!.year,
            schedule.specificDate!.month,
            schedule.specificDate!.day,
          );
          final targetDate = DateTime(date.year, date.month, date.day);
          return scheduleDate.isAtSameMomentAs(targetDate);
        }
        return false;
      }

      // Regular schedules - check day match
      return schedule.day.toLowerCase() == dayName.toLowerCase();
    }).toList();
  }

  /// Check if a schedule conflicts with existing schedules
  static bool hasScheduleConflict(
      Schedule newSchedule, List<Schedule> existingSchedules) {
    final activeSchedules = getActiveSchedules(existingSchedules);

    for (final existing in activeSchedules) {
      if (existing.id == newSchedule.id) continue; // Skip self

      // Check for time overlap on the same day/date
      if (_schedulesOverlap(newSchedule, existing)) {
        return true;
      }
    }

    return false;
  }

  /// Get expired schedules for cleanup
  static List<Schedule> getExpiredSchedules(List<Schedule> allSchedules) {
    return allSchedules.where((schedule) {
      return schedule.isReplacement && schedule.isExpired;
    }).toList();
  }

  /// Sort schedules by priority (today's first, then by time)
  static List<Schedule> sortSchedulesByPriority(List<Schedule> schedules) {
    final today = DateTime.now();
    final todaySchedules = <Schedule>[];
    final futureSchedules = <Schedule>[];

    for (final schedule in schedules) {
      if (_isScheduleForToday(schedule, today)) {
        todaySchedules.add(schedule);
      } else {
        futureSchedules.add(schedule);
      }
    }

    // Sort each group by start time
    todaySchedules.sort((a, b) => a.startTime.compareTo(b.startTime));
    futureSchedules.sort((a, b) => a.startTime.compareTo(b.startTime));

    return [...todaySchedules, ...futureSchedules];
  }

  /// Get schedule display info with context
  static String getScheduleDisplayInfo(Schedule schedule) {
    final timeInfo =
        '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}';

    if (schedule.isReplacement) {
      if (schedule.specificDate != null) {
        final dateStr =
            '${schedule.specificDate!.day}/${schedule.specificDate!.month}';
        return '${schedule.displayTitle} • $timeInfo • $dateStr';
      }
    }

    return '${schedule.displayTitle} • $timeInfo • ${schedule.location}';
  }

  /// Get schedule status for UI display
  static ScheduleDisplayStatus getScheduleStatus(Schedule schedule) {
    if (!schedule.isActive) {
      return ScheduleDisplayStatus.inactive;
    }

    if (schedule.type == ScheduleType.cancelled) {
      return ScheduleDisplayStatus.cancelled;
    }

    if (schedule.isReplacement && schedule.isExpired) {
      return ScheduleDisplayStatus.expired;
    }

    final today = DateTime.now();
    if (_isScheduleForToday(schedule, today)) {
      return ScheduleDisplayStatus.today;
    }

    return ScheduleDisplayStatus.upcoming;
  }

  // Private helper methods
  static bool _schedulesOverlap(Schedule schedule1, Schedule schedule2) {
    // Check if they're on the same day/date
    if (!_schedulesOnSameDay(schedule1, schedule2)) {
      return false;
    }

    // Check time overlap
    final start1 = schedule1.startTime;
    final end1 = schedule1.endTime;
    final start2 = schedule2.startTime;
    final end2 = schedule2.endTime;

    return start1.isBefore(end2) && start2.isBefore(end1);
  }

  static bool _schedulesOnSameDay(Schedule schedule1, Schedule schedule2) {
    // If both are replacements, check specific dates
    if (schedule1.isReplacement && schedule2.isReplacement) {
      if (schedule1.specificDate != null && schedule2.specificDate != null) {
        final date1 = DateTime(
          schedule1.specificDate!.year,
          schedule1.specificDate!.month,
          schedule1.specificDate!.day,
        );
        final date2 = DateTime(
          schedule2.specificDate!.year,
          schedule2.specificDate!.month,
          schedule2.specificDate!.day,
        );
        return date1.isAtSameMomentAs(date2);
      }
      return false;
    }

    // If one is replacement, check if it falls on the other's regular day
    if (schedule1.isReplacement && schedule2.isRegular) {
      if (schedule1.specificDate != null) {
        final weekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
        final dayName = weekdays[schedule1.specificDate!.weekday - 1];
        return dayName.toLowerCase() == schedule2.day.toLowerCase();
      }
      return false;
    }

    if (schedule2.isReplacement && schedule1.isRegular) {
      return _schedulesOnSameDay(schedule2, schedule1);
    }

    // Both are regular - check day names
    return schedule1.day.toLowerCase() == schedule2.day.toLowerCase();
  }

  static bool _isScheduleForToday(Schedule schedule, DateTime today) {
    if (schedule.isReplacement) {
      if (schedule.specificDate != null) {
        final scheduleDate = DateTime(
          schedule.specificDate!.year,
          schedule.specificDate!.month,
          schedule.specificDate!.day,
        );
        final todayDate = DateTime(today.year, today.month, today.day);
        return scheduleDate.isAtSameMomentAs(todayDate);
      }
      return false;
    }

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final todayName = weekdays[today.weekday - 1];
    return schedule.day.toLowerCase() == todayName.toLowerCase();
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Enum for schedule display status
enum ScheduleDisplayStatus {
  today,
  upcoming,
  expired,
  cancelled,
  inactive,
}

/// Extension for easy status checking
extension ScheduleDisplayStatusExtension on ScheduleDisplayStatus {
  bool get isActive =>
      this == ScheduleDisplayStatus.today ||
      this == ScheduleDisplayStatus.upcoming;

  bool get needsAttention =>
      this == ScheduleDisplayStatus.expired ||
      this == ScheduleDisplayStatus.cancelled;

  String get displayText {
    switch (this) {
      case ScheduleDisplayStatus.today:
        return 'Today';
      case ScheduleDisplayStatus.upcoming:
        return 'Upcoming';
      case ScheduleDisplayStatus.expired:
        return 'Expired';
      case ScheduleDisplayStatus.cancelled:
        return 'Cancelled';
      case ScheduleDisplayStatus.inactive:
        return 'Inactive';
    }
  }
}
