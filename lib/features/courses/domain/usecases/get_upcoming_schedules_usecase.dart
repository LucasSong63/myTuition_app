import '../entities/schedule.dart';
import '../repositories/course_repository.dart';

class GetUpcomingSchedulesUseCase {
  final CourseRepository repository;

  GetUpcomingSchedulesUseCase(this.repository);

  Future<List<Schedule>> execute(String studentId) {
    return repository.getUpcomingSchedules(studentId);
  }
}
