import '../repositories/student_management_repository.dart';

class GetAvailableCoursesUseCase {
  final StudentManagementRepository repository;

  GetAvailableCoursesUseCase(this.repository);

  Future<List<Map<String, dynamic>>> execute(String studentId) {
    return repository.getAvailableCourses(studentId);
  }
}
