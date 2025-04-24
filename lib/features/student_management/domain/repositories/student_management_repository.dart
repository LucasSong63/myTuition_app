import '../entities/student.dart';

abstract class StudentManagementRepository {
  /// Get all students
  Future<List<Student>> getAllStudents();

  /// Get a specific student by ID
  Future<Student> getStudentById(String studentId);

  /// Get courses enrolled by a student
  Future<List<Map<String, dynamic>>> getEnrolledCourses(String studentId);

  /// Get courses available for enrollment
  Future<List<Map<String, dynamic>>> getAvailableCourses(String studentId);

  /// Enroll a student in a course
  Future<void> enrollStudentInCourse(String studentId, String courseId);

  /// Remove a student from a course
  Future<void> removeStudentFromCourse(String studentId, String courseId);

  /// Update student profile information
  Future<void> updateStudentProfile(
    String userId, {
    String? name,
    String? phone,
    int? grade,
    List<String>? subjects,
  });
}
