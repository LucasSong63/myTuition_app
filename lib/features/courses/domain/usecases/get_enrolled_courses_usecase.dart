import '../entities/course.dart';
import '../repositories/course_repository.dart';

class GetEnrolledCoursesUseCase {
  final CourseRepository repository;

  GetEnrolledCoursesUseCase(this.repository);

  Future<List<Course>> execute(String studentId) {
    return repository.getEnrolledCourses(studentId);
  }
}
