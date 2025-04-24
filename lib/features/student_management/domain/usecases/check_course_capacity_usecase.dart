import '../repositories/student_management_repository.dart';

class CheckCourseCapacityUseCase {
  final StudentManagementRepository repository;

  CheckCourseCapacityUseCase(this.repository);

  Future<bool> execute(String courseId) {
    return repository.checkCourseCapacity(courseId);
  }
}
