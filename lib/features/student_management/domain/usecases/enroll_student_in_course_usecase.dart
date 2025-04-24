import '../repositories/student_management_repository.dart';

class EnrollStudentInCourseUseCase {
  final StudentManagementRepository repository;

  EnrollStudentInCourseUseCase(this.repository);

  Future<void> execute(String studentId, String courseId) {
    return repository.enrollStudentInCourse(studentId, courseId);
  }
}
