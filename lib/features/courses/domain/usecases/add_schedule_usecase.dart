import '../entities/schedule.dart';
import '../repositories/course_repository.dart';

class AddScheduleUseCase {
  final CourseRepository repository;

  AddScheduleUseCase(this.repository);

  Future<void> execute(String courseId, Schedule schedule) {
    return repository.addSchedule(courseId, schedule);
  }
}
