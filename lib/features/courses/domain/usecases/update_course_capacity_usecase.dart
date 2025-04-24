import '../repositories/course_repository.dart';

class UpdateCourseCapacityUseCase {
  final CourseRepository repository;

  UpdateCourseCapacityUseCase(this.repository);

  Future<void> execute(String courseId, int capacity) {
    return repository.updateCourseCapacity(courseId, capacity);
  }
}
