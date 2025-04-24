import '../repositories/student_management_repository.dart';

class GetEnrolledCoursesUseCase {
  final StudentManagementRepository repository;

  GetEnrolledCoursesUseCase(this.repository);

  Future<List<Map<String, dynamic>>> execute(String studentId) {
    return repository.getEnrolledCourses(studentId);
  }
}
