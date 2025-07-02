// lib/features/courses/domain/usecases/get_recent_activities_usecase.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/activity.dart';

class GetRecentActivitiesUseCase {
  final FirebaseFirestore _firestore;

  GetRecentActivitiesUseCase(this._firestore);

  Future<List<Activity>> execute(String courseId) async {
    final List<Activity> activities = [];

    try {
      // Get recent attendance records
      final attendanceActivities = await _getAttendanceActivities(courseId);
      activities.addAll(attendanceActivities);

      // Get recent task assignments
      final taskActivities = await _getTaskActivities(courseId);
      activities.addAll(taskActivities);

      // Get recent schedule updates
      final scheduleActivities = await _getScheduleActivities(courseId);
      activities.addAll(scheduleActivities);

      // Sort by most recent first and take top 5
      activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Return top 5 most recent activities
      return activities.take(5).toList();
    } catch (e) {
      print('Error fetching recent activities: $e');
      return [];
    }
  }

  Future<List<Activity>> _getAttendanceActivities(String courseId) async {
    try {
      // Get attendance records from last 30 days for this course
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final snapshot = await _firestore
          .collection('attendance')
          .where('courseId', isEqualTo: courseId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final List<Activity> activities = [];
      
      // Group by date to avoid showing multiple entries for same attendance session
      final Map<String, QueryDocumentSnapshot> latestByDate = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final dateKey = '${createdAt.year}-${createdAt.month}-${createdAt.day}';
        
        // Keep only the latest attendance record for each date
        if (!latestByDate.containsKey(dateKey) || 
            createdAt.isAfter((latestByDate[dateKey]!.data() as Map<String, dynamic>)['createdAt'].toDate())) {
          latestByDate[dateKey] = doc;
        }
      }

      for (final doc in latestByDate.values) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        
        activities.add(Activity(
          id: doc.id,
          type: ActivityType.attendance,
          title: 'Attendance taken',
          description: 'Class attendance recorded',
          createdAt: createdAt,
          courseId: courseId,
          metadata: {
            'date': createdAt.toIso8601String(),
            'status': data['status'] ?? 'unknown',
          },
        ));
      }

      return activities;
    } catch (e) {
      print('Error fetching attendance activities: $e');
      return [];
    }
  }

  Future<List<Activity>> _getTaskActivities(String courseId) async {
    try {
      // Get recent tasks for this course from last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final snapshot = await _firestore
          .collection('tasks')
          .where('courseId', isEqualTo: courseId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final List<Activity> activities = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final title = data['title'] as String? ?? 'Untitled Task';
        
        activities.add(Activity(
          id: doc.id,
          type: ActivityType.task,
          title: 'New task assigned',
          description: title,
          createdAt: createdAt,
          courseId: courseId,
          metadata: {
            'taskTitle': title,
            'taskId': doc.id,
          },
        ));
      }

      return activities;
    } catch (e) {
      print('Error fetching task activities: $e');
      return [];
    }
  }

  Future<List<Activity>> _getScheduleActivities(String courseId) async {
    try {
      // Get course document to access schedules array
      final courseDoc = await _firestore
          .collection('classes')
          .doc(courseId)
          .get();

      if (!courseDoc.exists) {
        return [];
      }

      final data = courseDoc.data() as Map<String, dynamic>;
      final schedules = data['schedules'] as List<dynamic>? ?? [];

      final List<Activity> activities = [];
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      for (final scheduleData in schedules) {
        final schedule = scheduleData as Map<String, dynamic>;
        
        // Check if schedule has createdAt field and is recent
        if (schedule['createdAt'] != null) {
          final createdAt = (schedule['createdAt'] as Timestamp).toDate();
          
          // Only include schedules created in last 30 days
          if (createdAt.isAfter(thirtyDaysAgo)) {
            final scheduleType = schedule['type'] as String? ?? 'regular';
            final day = schedule['day'] as String? ?? 'Unknown';
            final location = schedule['location'] as String? ?? 'Unknown location';
            
            String title = 'Schedule updated';
            String description = 'Class schedule modified';
            
            // Customize title and description based on schedule type
            if (scheduleType == 'replacement') {
              title = 'Replacement class added';
              description = 'Makeup class scheduled for $day at $location';
            } else if (scheduleType == 'regular') {
              title = 'Regular schedule added';
              description = '$day class at $location';
            }
            
            activities.add(Activity(
              id: schedule['id'] as String? ?? 'unknown',
              type: ActivityType.schedule,
              title: title,
              description: description,
              createdAt: createdAt,
              courseId: courseId,
              metadata: {
                'scheduleType': scheduleType,
                'day': day,
                'location': location,
                'scheduleId': schedule['id'],
              },
            ));
          }
        }
      }

      return activities;
    } catch (e) {
      print('Error fetching schedule activities: $e');
      return [];
    }
  }
}
