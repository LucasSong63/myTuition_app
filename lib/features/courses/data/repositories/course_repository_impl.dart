// lib/features/courses/data/repositories/course_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/repositories/course_repository.dart';
import '../models/course_model.dart';
import '../models/schedule_model.dart';

class CourseRepositoryImpl implements CourseRepository {
  final FirebaseFirestore _firestore;

  CourseRepositoryImpl(this._firestore);

  @override
  Future<List<Course>> getEnrolledCourses(String studentId) async {
    try {
      print("Querying for courses with student ID: $studentId");
      final snapshot = await _firestore
          .collection('classes')
          .where('students', arrayContains: studentId)
          .get();

      print("Query returned ${snapshot.docs.length} courses");
      if (snapshot.docs.isEmpty) {
        print("No courses found with student ID: $studentId");
      } else {
        print(
            "Found courses: ${snapshot.docs.map((doc) => doc.id).join(', ')}");
      }

      return snapshot.docs
          .map((doc) => CourseModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("Error in getEnrolledCourses: $e");
      throw Exception('Failed to get enrolled courses: $e');
    }
  }

  @override
  Future<Course> getCourseById(String courseId) async {
    try {
      final doc = await _firestore.collection('classes').doc(courseId).get();

      if (!doc.exists) {
        throw Exception('Course not found');
      }

      return CourseModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get course details: $e');
    }
  }

  @override
  Future<List<Schedule>> getUpcomingSchedules(String studentId) async {
    try {
      // First get all enrolled courses
      final coursesSnapshot = await _firestore
          .collection('classes')
          .where('students', arrayContains: studentId)
          .get();

      // Extract all schedules
      final List<Schedule> allSchedules = [];

      for (var doc in coursesSnapshot.docs) {
        final data = doc.data();
        final courseId = doc.id;
        final subject = data['subject'] as String;
        final grade = data['grade'] as int;

        // Extract schedules array
        if (data['schedules'] != null) {
          final schedules = data['schedules'] as List<dynamic>;

          for (int i = 0; i < schedules.length; i++) {
            final scheduleData = schedules[i] as Map<String, dynamic>;
            scheduleData['id'] = scheduleData['id'] ?? '$courseId-schedule-$i';

            final schedule = ScheduleModel.fromMap(
              scheduleData,
              scheduleData['id'] as String,
              courseId: courseId,
              subject: subject,
              grade: grade,
            );

            // Only include active schedules and filter expired replacement schedules
            if (schedule.isActive && !schedule.isExpired) {
              allSchedules.add(schedule);
            }
          }
        }
      }

      // Sort schedules by day of week and then by start time
      allSchedules.sort((a, b) {
        // First sort by day of week
        final aDayIndex = _getDayIndex(a.day);
        final bDayIndex = _getDayIndex(b.day);
        if (aDayIndex != bDayIndex) {
          return aDayIndex.compareTo(bDayIndex);
        }
        // Then sort by start time
        return a.startTime.hour.compareTo(b.startTime.hour);
      });

      return allSchedules;
    } catch (e) {
      throw Exception('Failed to get upcoming schedules: $e');
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
    return days.indexOf(day.trim());
  }

  @override
  Future<List<Course>> getTutorCourses(String tutorId) async {
    try {
      print("Fetching all classes for tutor access");
      final snapshot = await _firestore.collection('classes').get();

      print("Query returned ${snapshot.docs.length} classes");
      return snapshot.docs
          .map((doc) => CourseModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("Error in getTutorCourses: $e");
      throw Exception('Failed to get tutor courses: $e');
    }
  }

  @override
  Future<void> addSchedule(String courseId, Schedule schedule) async {
    try {
      final courseDoc =
          await _firestore.collection('classes').doc(courseId).get();

      if (!courseDoc.exists) {
        throw Exception('Course not found');
      }

      final List<dynamic> existingSchedules =
          courseDoc.data()?['schedules'] ?? [];

      // Convert Schedule to Map using ScheduleModel
      final scheduleModel = ScheduleModel(
        id: schedule.id,
        courseId: schedule.courseId,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        day: schedule.day,
        location: schedule.location,
        subject: schedule.subject,
        grade: schedule.grade,
        type: schedule.type,
        specificDate: schedule.specificDate,
        replacesDate: schedule.replacesDate,
        reason: schedule.reason,
        isActive: schedule.isActive,
        createdAt: schedule.createdAt ?? DateTime.now(),
      );

      existingSchedules.add(scheduleModel.toMap());

      await _firestore.collection('classes').doc(courseId).update({
        'schedules': existingSchedules,
      });
    } catch (e) {
      throw Exception('Failed to add schedule: $e');
    }
  }

  @override
  Future<void> updateSchedule(
      String courseId, String scheduleId, Schedule updatedSchedule) async {
    try {
      final courseDoc =
          await _firestore.collection('classes').doc(courseId).get();

      if (!courseDoc.exists) {
        throw Exception('Course not found');
      }

      final List<dynamic> existingSchedules =
          courseDoc.data()?['schedules'] ?? [];

      // Find the schedule by ID
      int scheduleIndex = -1;
      for (int i = 0; i < existingSchedules.length; i++) {
        final scheduleData = existingSchedules[i] as Map<String, dynamic>;
        final currentId = scheduleData['id'] as String?;

        if (currentId == scheduleId) {
          scheduleIndex = i;
          break;
        }

        // Fallback: try old ID format for backwards compatibility
        if (currentId == null && scheduleId == '$courseId-schedule-$i') {
          scheduleIndex = i;
          break;
        }
      }

      if (scheduleIndex == -1) {
        throw Exception('Schedule not found');
      }

      // Convert updated schedule to map
      final scheduleModel = ScheduleModel(
        id: updatedSchedule.id,
        courseId: updatedSchedule.courseId,
        startTime: updatedSchedule.startTime,
        endTime: updatedSchedule.endTime,
        day: updatedSchedule.day,
        location: updatedSchedule.location,
        subject: updatedSchedule.subject,
        grade: updatedSchedule.grade,
        type: updatedSchedule.type,
        specificDate: updatedSchedule.specificDate,
        replacesDate: updatedSchedule.replacesDate,
        reason: updatedSchedule.reason,
        isActive: updatedSchedule.isActive,
        createdAt: updatedSchedule.createdAt,
      );

      // Update the schedule at the specified index
      existingSchedules[scheduleIndex] = scheduleModel.toMap();

      await _firestore.collection('classes').doc(courseId).update({
        'schedules': existingSchedules,
      });
    } catch (e) {
      throw Exception('Failed to update schedule: $e');
    }
  }

  @override
  Future<void> deleteSchedule(String courseId, String scheduleId) async {
    try {
      final courseDoc =
          await _firestore.collection('classes').doc(courseId).get();

      if (!courseDoc.exists) {
        throw Exception('Course not found');
      }

      final List<dynamic> existingSchedules =
          courseDoc.data()?['schedules'] ?? [];

      // Find the schedule by ID
      int scheduleIndex = -1;
      for (int i = 0; i < existingSchedules.length; i++) {
        final scheduleData = existingSchedules[i] as Map<String, dynamic>;
        final currentId = scheduleData['id'] as String?;

        if (currentId == scheduleId) {
          scheduleIndex = i;
          break;
        }

        // Fallback: try old ID format for backwards compatibility
        if (currentId == null && scheduleId == '$courseId-schedule-$i') {
          scheduleIndex = i;
          break;
        }
      }

      if (scheduleIndex == -1) {
        throw Exception('Schedule not found');
      }

      // Remove the schedule at the specified index
      existingSchedules.removeAt(scheduleIndex);

      await _firestore.collection('classes').doc(courseId).update({
        'schedules': existingSchedules,
      });
    } catch (e) {
      throw Exception('Failed to delete schedule: $e');
    }
  }

  @override
  Future<void> updateCourseActiveStatus(String courseId, bool isActive) async {
    try {
      await _firestore.collection('classes').doc(courseId).update({
        'isActive': isActive,
      });
    } catch (e) {
      throw Exception('Failed to update course active status: $e');
    }
  }

  @override
  Future<void> updateCourseCapacity(String courseId, int capacity) async {
    try {
      if (capacity < 1) {
        throw Exception('Capacity must be at least 1 student');
      }

      // First get the current course to check if the new capacity is valid
      final courseDoc =
          await _firestore.collection('classes').doc(courseId).get();

      if (!courseDoc.exists) {
        throw Exception('Course not found. Please refresh and try again.');
      }

      final data = courseDoc.data()!;
      final currentStudents = (data['students'] as List<dynamic>? ?? []).length;

      // Check if the new capacity is less than the current enrollment
      if (capacity < currentStudents) {
        throw Exception(
            'Cannot set capacity below current enrollment ($currentStudents students). Please unenroll some students first.');
      }

      // Update the capacity field
      await _firestore.collection('classes').doc(courseId).update({
        'capacity': capacity,
      });
    } catch (e) {
      if (e is Exception) {
        // Pass through our custom exceptions
        throw e;
      }
      // Handle Firebase exceptions separately
      throw Exception(
          'Network error while updating capacity. Please try again.');
    }
  }

  @override
  Future<List<String>> getEnrolledStudentsForCourse(String courseId) async {
    try {
      final courseDoc =
          await _firestore.collection('classes').doc(courseId).get();

      if (!courseDoc.exists) {
        return [];
      }

      final List<dynamic> enrolledStudentsRaw =
          courseDoc.data()?['students'] ?? [];
      return enrolledStudentsRaw.map((s) => s.toString()).toList();
    } catch (e) {
      print('Error getting enrolled students: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getCourseDetailsById(String courseId) async {
    try {
      final doc = await _firestore.collection('classes').doc(courseId).get();

      if (!doc.exists) {
        return {'subject': 'Unknown Course', 'grade': null};
      }

      return {
        'subject': doc.data()?['subject'] ?? 'Unknown Course',
        'grade': doc.data()?['grade'],
      };
    } catch (e) {
      print('Error getting course details: $e');
      return {'subject': 'Unknown Course', 'grade': null};
    }
  }

  /// Get schedules relevant for a specific date
  /// This method helps the attendance system filter schedules appropriately
  Future<List<Schedule>> getSchedulesForDate(
      String courseId, DateTime date) async {
    try {
      final course = await getCourseById(courseId);

      // Filter schedules that are relevant for the given date
      final relevantSchedules = course.schedules.where((schedule) {
        return schedule.isRelevantForDate(date) && schedule.isActive;
      }).toList();

      return relevantSchedules;
    } catch (e) {
      throw Exception('Failed to get schedules for date: $e');
    }
  }

  /// Clean up expired replacement schedules (optional utility method)
  Future<void> cleanupExpiredReplacementSchedules(String courseId) async {
    try {
      final courseDoc =
          await _firestore.collection('classes').doc(courseId).get();

      if (!courseDoc.exists) {
        throw Exception('Course not found');
      }

      final List<dynamic> existingSchedules =
          courseDoc.data()?['schedules'] ?? [];

      final List<dynamic> activeSchedules = [];
      bool hasExpiredSchedules = false;

      for (var scheduleData in existingSchedules) {
        final scheduleMap = scheduleData as Map<String, dynamic>;

        // Create a Schedule object to check if it's expired
        final schedule = ScheduleModel.fromMap(
          scheduleMap,
          scheduleMap['id'] ?? 'temp-id',
          courseId: courseId,
          subject: 'temp',
          grade: 1,
        );

        if (!schedule.isExpired) {
          activeSchedules.add(scheduleData);
        } else {
          hasExpiredSchedules = true;
          print('Removing expired replacement schedule: ${schedule.id}');
        }
      }

      // Only update if there were expired schedules to remove
      if (hasExpiredSchedules) {
        await _firestore.collection('classes').doc(courseId).update({
          'schedules': activeSchedules,
        });
        print('Cleaned up expired replacement schedules for course: $courseId');
      }
    } catch (e) {
      print('Error cleaning up expired schedules: $e');
      // Don't throw error as this is a cleanup operation
    }
  }
}
