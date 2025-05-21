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
            scheduleData['id'] = '$courseId-schedule-$i'; // Create a unique ID

            final schedule = ScheduleModel.fromMap(
              scheduleData,
              '$courseId-schedule-$i',
              courseId: courseId,
              subject: subject,
              grade: grade,
            );

            allSchedules.add(schedule);
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

      // Convert Schedule to Map
      final scheduleMap = {
        'day': schedule.day,
        'startTime': schedule.startTime,
        'endTime': schedule.endTime,
        'location': schedule.location,
      };

      existingSchedules.add(scheduleMap);

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

      // Extract the index from the scheduleId (e.g., courseId-schedule-1 -> index 1)
      final idParts = scheduleId.split('-');
      if (idParts.length < 3) {
        throw Exception('Invalid schedule ID format');
      }

      final scheduleIndex = int.tryParse(idParts.last);
      if (scheduleIndex == null || scheduleIndex >= existingSchedules.length) {
        throw Exception('Schedule not found');
      }

      // Update the schedule at the specified index
      existingSchedules[scheduleIndex] = {
        'day': updatedSchedule.day,
        'startTime': updatedSchedule.startTime,
        'endTime': updatedSchedule.endTime,
        'location': updatedSchedule.location,
      };

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

      // Extract the index from the scheduleId
      final idParts = scheduleId.split('-');
      if (idParts.length < 3) {
        throw Exception('Invalid schedule ID format');
      }

      final scheduleIndex = int.tryParse(idParts.last);
      if (scheduleIndex == null || scheduleIndex >= existingSchedules.length) {
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
}
