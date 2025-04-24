import '../repositories/student_management_repository.dart';

class RemoveStudentFromCourseUseCase {
  final StudentManagementRepository repository;

  RemoveStudentFromCourseUseCase(this.repository);

  Future<void> execute(String studentId, String courseId) {
    return repository.removeStudentFromCourse(studentId, courseId);
  }
}
