import '../entities/course.dart';
import '../repositories/course_repository.dart';

class GetTutorCoursesUseCase {
  final CourseRepository repository;

  GetTutorCoursesUseCase(this.repository);

  Future<List<Course>> execute(String tutorId) {
    return repository.getTutorCourses(tutorId);
  }
}
