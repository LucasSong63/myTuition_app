// lib/core/utils/task_utils.dart

import 'package:intl/intl.dart';

/// Utility functions for task-related operations
class TaskUtils {
  /// Determines if a task is overdue based on the due date and completion status
  /// Only considers a task overdue if:
  /// 1. It has a due date
  /// 2. It is not completed
  /// 3. The current date is AFTER the due date (not on the same day)
  static bool isTaskOverdue(DateTime? dueDate, bool isCompleted) {
    // If task is completed or has no due date, it's not overdue
    if (isCompleted || dueDate == null) {
      return false;
    }

    // Get dates without time component for proper comparison
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final taskDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    // Only overdue if today is AFTER due date (not the same day)
    return today.isAfter(taskDueDate);
  }

  /// Standardized date formatter for due dates (e.g., "12 Apr 2025")
  static final DateFormat shortDateFormat = DateFormat('d MMM yyyy');

  /// Standardized date formatter for detailed dates (e.g., "Monday, April 12, 2025")
  static final DateFormat longDateFormat = DateFormat('EEEE, MMMM d, yyyy');

  /// Standardized date formatter for completed dates (e.g., "12 Apr 2025")
  static final DateFormat completedDateFormat = DateFormat('dd MMM yyyy');

  /// Returns appropriate status text based on task state
  /// Always prioritizes completion status over overdue status
  static String getTaskStatusText(bool isCompleted, bool isOverdue) {
    if (isCompleted) return 'Completed';
    if (isOverdue) return 'Overdue';
    return 'Pending';
  }
}
