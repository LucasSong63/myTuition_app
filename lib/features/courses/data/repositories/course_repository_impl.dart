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
}
