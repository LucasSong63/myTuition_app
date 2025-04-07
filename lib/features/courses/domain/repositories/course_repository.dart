import '../entities/course.dart';
import '../entities/schedule.dart';

abstract class CourseRepository {
  // Get all courses a student is enrolled in
  Future<List<Course>> getEnrolledCourses(String studentId);

  // Get a specific course by ID
  Future<Course> getCourseById(String courseId);

  // Get upcoming schedules for a student
  Future<List<Schedule>> getUpcomingSchedules(String studentId);
}
