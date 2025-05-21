import '../entities/course.dart';
import '../entities/schedule.dart';

abstract class CourseRepository {
  // Get all courses a student is enrolled in
  Future<List<Course>> getEnrolledCourses(String studentId);

  // Get a specific course by ID
  Future<Course> getCourseById(String courseId);

  // Get upcoming schedules for a student
  Future<List<Schedule>> getUpcomingSchedules(String studentId);

  Future<List<Course>> getTutorCourses(String tutorId);

  // Add a new schedule to a course
  Future<void> addSchedule(String courseId, Schedule schedule);

  // Update an existing schedule
  Future<void> updateSchedule(
      String courseId, String scheduleId, Schedule updatedSchedule);

  // Delete a schedule
  Future<void> deleteSchedule(String courseId, String scheduleId);

  Future<void> updateCourseActiveStatus(String courseId, bool isActive);

  // Update course capacity
  Future<void> updateCourseCapacity(String courseId, int capacity);

  /// Get all students enrolled in a specific course
  Future<List<String>> getEnrolledStudentsForCourse(String courseId);

  /// Get course details by ID for better notification messages
  Future<Map<String, dynamic>> getCourseDetailsById(String courseId);
}
