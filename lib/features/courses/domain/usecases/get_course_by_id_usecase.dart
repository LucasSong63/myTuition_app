import '../entities/course.dart';
import '../repositories/course_repository.dart';

class GetCourseByIdUseCase {
  final CourseRepository repository;

  GetCourseByIdUseCase(this.repository);

  Future<Course> execute(String courseId) {
    return repository.getCourseById(courseId);
  }
}
