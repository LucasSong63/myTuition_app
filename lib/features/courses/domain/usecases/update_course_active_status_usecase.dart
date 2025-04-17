import '../repositories/course_repository.dart';

class UpdateCourseActiveStatusUseCase {
  final CourseRepository repository;

  UpdateCourseActiveStatusUseCase(this.repository);

  Future<void> execute(String courseId, bool isActive) {
    return repository.updateCourseActiveStatus(courseId, isActive);
  }
}
