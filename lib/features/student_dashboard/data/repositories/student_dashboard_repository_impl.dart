// lib/features/student_dashboard/data/repositories/student_dashboard_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/student_dashboard_stats.dart';
import '../../domain/repositories/student_dashboard_repository.dart';

class StudentDashboardRepositoryImpl implements StudentDashboardRepository {
  final FirebaseFirestore _firestore;

  StudentDashboardRepositoryImpl(this._firestore);

  @override
  Future<StudentDashboardStats> getStudentDashboardStats(
      String studentId) async {
    // This method orchestrates all the individual calls
    // But we'll use the use case for this instead
    throw UnimplementedError('Use GetStudentDashboardStatsUseCase instead');
  }

  @override
  Future<int> getEnrolledCoursesCount(String studentId) async {
    try {
      print("=== DEBUGGING ENROLLED COURSES ===");
      print("Looking for studentId: '$studentId'");

      // First, let's check what courses exist
      final allCoursesSnapshot = await _firestore.collection('classes').get();
      print("Total courses in database: ${allCoursesSnapshot.docs.length}");

      // Check each course to see if this student is enrolled
      int enrolledCount = 0;
      for (var doc in allCoursesSnapshot.docs) {
        final data = doc.data();
        final courseId = doc.id;
        final students = data['students'] as List<dynamic>? ?? [];
        final isActive = data['isActive'] ?? true;

        print("Course $courseId:");
        print("  - isActive: $isActive");
        print("  - students: $students");
        print("  - contains '$studentId': ${students.contains(studentId)}");

        if (isActive && students.contains(studentId)) {
          enrolledCount++;
          print("  ✅ ENROLLED in $courseId");
        }
      }

      print("Final enrolled count: $enrolledCount");

      // Also try the original query to compare
      final snapshot = await _firestore
          .collection('classes')
          .where('students', arrayContains: studentId)
          .where('isActive', isEqualTo: true)
          .get();

      print("Query result count: ${snapshot.docs.length}");
      print("Query results: ${snapshot.docs.map((doc) => doc.id).toList()}");

      return enrolledCount; // Return the manual count for now
    } catch (e) {
      print("Error in getEnrolledCoursesCount: $e");
      return 0;
    }
  }

  @override
  Future<int> getPendingTasksCount(String studentId) async {
    try {
      print("=== DEBUGGING PENDING TASKS (CORRECTED LOGIC) ===");
      print("Looking for studentId: '$studentId'");

      // STEP 1: Get all enrolled courses for this student
      final enrolledCoursesSnapshot = await _firestore
          .collection('classes')
          .where('students', arrayContains: studentId)
          .where('isActive', isEqualTo: true)
          .get();

      print("Enrolled courses count: ${enrolledCoursesSnapshot.docs.length}");

      List<String> enrolledCourseIds = [];
      for (var courseDoc in enrolledCoursesSnapshot.docs) {
        enrolledCourseIds.add(courseDoc.id);
        print("  - Enrolled in course: ${courseDoc.id}");
      }

      if (enrolledCourseIds.isEmpty) {
        print("No enrolled courses found. Pending tasks: 0");
        return 0;
      }

      // STEP 2: Get all tasks for these enrolled courses (TOTAL TASKS)
      int totalTasks = 0;
      List<String> allTaskIds = [];

      for (String courseId in enrolledCourseIds) {
        final tasksSnapshot = await _firestore
            .collection('tasks')
            .where('courseId', isEqualTo: courseId)
            .get();

        print("Course $courseId has ${tasksSnapshot.docs.length} tasks");

        for (var taskDoc in tasksSnapshot.docs) {
          allTaskIds.add(taskDoc.id);
          totalTasks++;
          print("  - Task: ${taskDoc.id} (${taskDoc.data()['title']})");
        }
      }

      print("TOTAL TASKS for student: $totalTasks");

      // STEP 3: Count completed tasks from student_tasks collection
      int completedTasks = 0;

      if (allTaskIds.isNotEmpty) {
        // Get all student_tasks for this student that are completed
        final completedTasksSnapshot = await _firestore
            .collection('student_tasks')
            .where('studentId', isEqualTo: studentId)
            .where('isCompleted', isEqualTo: true)
            .get();

        print(
            "Found ${completedTasksSnapshot.docs.length} completed student_tasks");

        // Count only completed tasks that are in the student's enrolled courses
        for (var studentTaskDoc in completedTasksSnapshot.docs) {
          final taskId = studentTaskDoc.data()['taskId'] as String;
          if (allTaskIds.contains(taskId)) {
            completedTasks++;
            print("  ✅ Completed task: $taskId");
          }
        }
      }

      print("COMPLETED TASKS: $completedTasks");

      // STEP 4: Calculate pending tasks
      final pendingTasks = totalTasks - completedTasks;
      print("PENDING TASKS: $totalTasks - $completedTasks = $pendingTasks");

      return pendingTasks < 0 ? 0 : pendingTasks; // Ensure non-negative
    } catch (e) {
      print("Error in getPendingTasksCount: $e");
      return 0;
    }
  }

  // Add a method to debug the student's actual data
  Future<void> debugStudentData(String studentId) async {
    try {
      print("=== DEBUGGING STUDENT DATA ===");
      print("StudentId: '$studentId'");

      // Check if user exists and get their data
      final userQuery = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print("❌ No user found with studentId: '$studentId'");
        return;
      }

      final userData = userQuery.docs.first.data();
      print("✅ User found:");
      print("  - Document ID: ${userQuery.docs.first.id}");
      print("  - Name: ${userData['name']}");
      print("  - Email: ${userData['email']}");
      print("  - StudentId: ${userData['studentId']}");
      print("  - Grade: ${userData['grade']}");
      print("  - Subjects: ${userData['subjects']}");
    } catch (e) {
      print("Error debugging student data: $e");
    }
  }

  @override
  Future<List<UpcomingClass>> getUpcomingClasses(String studentId) async {
    try {
      // Get all enrolled courses
      final coursesSnapshot = await _firestore
          .collection('classes')
          .where('students', arrayContains: studentId)
          .where('isActive', isEqualTo: true)
          .get();

      final List<UpcomingClass> upcomingClasses = [];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final nextWeek =
          today.add(const Duration(days: 7)); // Fixed: 7 days from today

      print("=== DEBUGGING UPCOMING CLASSES ===");
      print("Current time: $now");
      print("Today: $today");
      print("Next week cutoff: $nextWeek");

      for (var courseDoc in coursesSnapshot.docs) {
        final courseData = courseDoc.data();
        final courseId = courseDoc.id;
        final subject = courseData['subject'] as String;
        final grade = courseData['grade'] as int;
        final courseName = '$subject Grade $grade';

        print("Processing course: $courseName");

        // Get schedules for this course
        final schedules = courseData['schedules'] as List<dynamic>? ?? [];
        print("Found ${schedules.length} schedules");

        for (var i = 0; i < schedules.length; i++) {
          final scheduleData = schedules[i] as Map<String, dynamic>;

          // Skip inactive schedules
          if (scheduleData['isActive'] != true) {
            print("  Skipping inactive schedule $i");
            continue;
          }

          final startTime = (scheduleData['startTime'] as Timestamp).toDate();
          final endTime = (scheduleData['endTime'] as Timestamp).toDate();
          final day = scheduleData['day'] as String;
          final location = scheduleData['location'] as String;
          final scheduleId = scheduleData['id'] ?? '$courseId-schedule-$i';

          // Parse schedule type
          final typeString = scheduleData['type'] as String? ?? 'regular';
          final isReplacement = typeString == 'replacement';
          final reason = scheduleData['reason'] as String?;

          print(
              "  Processing schedule: $day ${startTime.hour}:${startTime.minute} ($typeString)");

          if (isReplacement) {
            // Handle replacement schedules
            final specificDate = scheduleData['specificDate'] != null
                ? (scheduleData['specificDate'] as Timestamp).toDate()
                : null;

            if (specificDate != null) {
              final scheduleDate = DateTime(
                  specificDate.year, specificDate.month, specificDate.day);

              print("    Replacement for: $scheduleDate");

              // Check if replacement is within our time window and not expired
              if (scheduleDate
                      .isAfter(today.subtract(const Duration(days: 1))) &&
                  scheduleDate.isBefore(nextWeek)) {
                final scheduleDateTime = DateTime(
                  scheduleDate.year,
                  scheduleDate.month,
                  scheduleDate.day,
                  startTime.hour,
                  startTime.minute,
                );

                // Only include future classes
                if (scheduleDateTime.isAfter(now)) {
                  print("    ✅ Adding replacement class: $scheduleDateTime");
                  upcomingClasses.add(UpcomingClass(
                    id: scheduleId,
                    courseId: courseId,
                    courseName: courseName,
                    subject: subject,
                    grade: grade,
                    startTime: scheduleDateTime,
                    endTime: DateTime(
                      scheduleDate.year,
                      scheduleDate.month,
                      scheduleDate.day,
                      endTime.hour,
                      endTime.minute,
                    ),
                    location: location,
                    day: _getDayName(scheduleDate.weekday),
                    // Use actual day name
                    isToday: _isSameDay(scheduleDate, today),
                    isReplacement: true,
                    reason: reason,
                  ));
                }
              }
            }
          } else {
            // Handle regular schedules
            final scheduleDayIndex = _getDayIndex(day);

            if (scheduleDayIndex == -1) {
              print("    Invalid day: $day");
              continue;
            }

            // Find next occurrence of this day within the next 7 days
            for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
              final checkDate = today.add(Duration(days: dayOffset));

              if (checkDate.weekday == scheduleDayIndex) {
                final scheduleDateTime = DateTime(
                  checkDate.year,
                  checkDate.month,
                  checkDate.day,
                  startTime.hour,
                  startTime.minute,
                );

                print(
                    "    Checking: $checkDate (${checkDate.weekday}) -> $scheduleDateTime");

                // Only include future classes
                if (scheduleDateTime.isAfter(now)) {
                  print("    ✅ Adding regular class: $scheduleDateTime");
                  upcomingClasses.add(UpcomingClass(
                    id: scheduleId,
                    courseId: courseId,
                    courseName: courseName,
                    subject: subject,
                    grade: grade,
                    startTime: scheduleDateTime,
                    endTime: DateTime(
                      checkDate.year,
                      checkDate.month,
                      checkDate.day,
                      endTime.hour,
                      endTime.minute,
                    ),
                    location: location,
                    day: day,
                    isToday: _isSameDay(checkDate, today),
                    isReplacement: false,
                  ));
                }
              }
            }
          }
        }
      }

      // Sort by start time
      upcomingClasses.sort((a, b) => a.startTime.compareTo(b.startTime));

      print("Total upcoming classes found: ${upcomingClasses.length}");
      for (var class_ in upcomingClasses) {
        print(
            "  - ${class_.courseName}: ${class_.startTime} (${class_.isToday ? 'TODAY' : class_.day})");
      }

      return upcomingClasses;
    } catch (e) {
      print('Error getting upcoming classes: $e');
      return [];
    }
  }

  @override
  Future<List<PendingTask>> getRecentPendingTasks(String studentId,
      {int limit = 5}) async {
    try {
      print("=== GETTING RECENT PENDING TASKS (CORRECTED) ===");
      print("StudentId: '$studentId', Limit: $limit");

      // Step 1: Get enrolled courses for this student
      final enrolledCoursesSnapshot = await _firestore
          .collection('classes')
          .where('students', arrayContains: studentId)
          .where('isActive', isEqualTo: true)
          .get();

      print("Enrolled courses: ${enrolledCoursesSnapshot.docs.length}");

      if (enrolledCoursesSnapshot.docs.isEmpty) {
        print("No enrolled courses found");
        return [];
      }

      // Step 2: Get ALL tasks for these enrolled courses
      List<Map<String, dynamic>> allTasks = [];
      Map<String, Map<String, dynamic>> courseDataCache = {};

      for (var courseDoc in enrolledCoursesSnapshot.docs) {
        final courseId = courseDoc.id;
        final courseData = courseDoc.data();

        // Cache course data for later use
        courseDataCache[courseId] = courseData;

        print(
            "Getting tasks for course: $courseId (${courseData['subject']} Grade ${courseData['grade']})");

        // Get all tasks for this course
        final tasksSnapshot = await _firestore
            .collection('tasks')
            .where('courseId', isEqualTo: courseId)
            .get();

        print("  Found ${tasksSnapshot.docs.length} tasks");

        for (var taskDoc in tasksSnapshot.docs) {
          final taskData = taskDoc.data();
          allTasks.add({
            'taskId': taskDoc.id,
            'taskData': taskData,
            'courseId': courseId,
          });
          print("    - Task: ${taskDoc.id} (${taskData['title']})");
        }
      }

      print("Total tasks across all courses: ${allTasks.length}");

      // Step 3: Get completed tasks from student_tasks collection
      final completedTasksSnapshot = await _firestore
          .collection('student_tasks')
          .where('studentId', isEqualTo: studentId)
          .where('isCompleted', isEqualTo: true)
          .get();

      // Create a set of completed task IDs for fast lookup
      Set<String> completedTaskIds = completedTasksSnapshot.docs
          .map((doc) => doc.data()['taskId'] as String)
          .toSet();

      print("Completed tasks: ${completedTaskIds.length}");
      print("Completed task IDs: $completedTaskIds");

      // Step 4: Filter out completed tasks to get pending tasks
      List<PendingTask> pendingTasks = [];
      final now = DateTime.now();

      for (var taskInfo in allTasks) {
        final taskId = taskInfo['taskId'] as String;

        // Skip if this task is completed
        if (completedTaskIds.contains(taskId)) {
          print("  Skipping completed task: $taskId");
          continue;
        }

        // Build PendingTask object
        final taskData = taskInfo['taskData'] as Map<String, dynamic>;
        final courseId = taskInfo['courseId'] as String;
        final courseData = courseDataCache[courseId]!;

        final dueDate = taskData['dueDate'] != null
            ? (taskData['dueDate'] as Timestamp).toDate()
            : null;
        final createdAt = (taskData['createdAt'] as Timestamp).toDate();

        // Calculate if overdue
        final isOverdue = dueDate != null && dueDate.isBefore(now);

        final pendingTask = PendingTask(
          id: taskId,
          // Using taskId as id since there's no student_task record yet
          taskId: taskId,
          title: taskData['title'] as String,
          description: taskData['description'] as String? ?? '',
          courseId: courseId,
          courseName: '${courseData['subject']} Grade ${courseData['grade']}',
          subject: courseData['subject'] as String,
          dueDate: dueDate,
          createdAt: createdAt,
          isOverdue: isOverdue,
        );

        pendingTasks.add(pendingTask);
        print("  Added pending task: $taskId (${pendingTask.title})");
      }

      print("Total pending tasks: ${pendingTasks.length}");

      // Step 5: Sort by priority (overdue first, then by due date, then by creation date)
      pendingTasks.sort((a, b) {
        // Overdue tasks first
        if (a.isOverdue && !b.isOverdue) return -1;
        if (!a.isOverdue && b.isOverdue) return 1;

        // Both have due dates - sort by due date
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        }

        // One has due date, prioritize it
        if (a.dueDate != null && b.dueDate == null) return -1;
        if (a.dueDate == null && b.dueDate != null) return 1;

        // Neither has due date - sort by creation date (newest first)
        return b.createdAt.compareTo(a.createdAt);
      });

      // Step 6: Return limited results
      final result = pendingTasks.take(limit).toList();
      print("Returning ${result.length} recent pending tasks");

      return result;
    } catch (e) {
      print('Error getting recent pending tasks: $e');
      return [];
    }
  }

  @override
  Future<List<StudentActivity>> getRecentActivities(String studentId,
      {int limit = 10}) async {
    try {
      final List<StudentActivity> activities = [];

      // Get recent task assignments
      final recentTasksSnapshot = await _firestore
          .collection('student_tasks')
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      for (var doc in recentTasksSnapshot.docs) {
        final data = doc.data();
        final taskId = data['taskId'] as String;
        final createdAt = data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now();

        // Get task details
        final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
        if (taskDoc.exists) {
          final taskData = taskDoc.data()!;
          final taskTitle = taskData['title'] as String;

          activities.add(StudentActivity(
            id: doc.id,
            type: StudentActivityType.taskAssigned,
            title: 'New Task Assigned',
            description: 'Task "$taskTitle" has been assigned to you',
            timestamp: createdAt,
            data: {
              'taskId': taskId,
              'taskTitle': taskTitle,
            },
          ));
        }
      }

      // Get recent task remarks/updates
      final studentTasksWithRemarksSnapshot = await _firestore
          .collection('student_tasks')
          .where('studentId', isEqualTo: studentId)
          .where('remarks', isNotEqualTo: '')
          .orderBy('remarks')
          .orderBy('updatedAt', descending: true)
          .limit(3)
          .get();

      for (var doc in studentTasksWithRemarksSnapshot.docs) {
        final data = doc.data();
        final taskId = data['taskId'] as String;
        final remarks = data['remarks'] as String;
        final updatedAt = data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now();

        // Get task details
        final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
        if (taskDoc.exists) {
          final taskData = taskDoc.data()!;
          final taskTitle = taskData['title'] as String;

          activities.add(StudentActivity(
            id: '${doc.id}_remarks',
            type: StudentActivityType.taskRemarks,
            title: 'Task Feedback',
            description: 'New feedback on "$taskTitle": $remarks',
            timestamp: updatedAt,
            data: {
              'taskId': taskId,
              'taskTitle': taskTitle,
              'remarks': remarks,
            },
          ));
        }
      }

      // Sort all activities by timestamp and limit
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return activities.take(limit).toList();
    } catch (e) {
      print('Error getting recent activities: $e');
      return [];
    }
  }

  @override
  Future<bool> hasOutstandingPayments(String studentId) async {
    try {
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('studentId', isEqualTo: studentId)
          .where('status', whereIn: ['unpaid', 'partial'])
          .limit(1)
          .get();

      return paymentsSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking outstanding payments: $e');
      return false;
    }
  }

  // Helper method to convert day name to index for sorting
  int _getDayIndex(String day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final index = days.indexWhere((d) => d.toLowerCase() == day.toLowerCase());
    return index == -1 ? -1 : index + 1; // Monday = 1, Sunday = 7
  }

  // Helper method to get day name from weekday index
  String _getDayName(int weekday) {
    const days = [
      'Monday', // 1
      'Tuesday', // 2
      'Wednesday', // 3
      'Thursday', // 4
      'Friday', // 5
      'Saturday', // 6
      'Sunday' // 7
    ];
    return weekday >= 1 && weekday <= 7 ? days[weekday - 1] : 'Unknown';
  }

  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
