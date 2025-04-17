import '../entities/schedule.dart';
import '../repositories/course_repository.dart';

class UpdateScheduleUseCase {
  final CourseRepository repository;

  UpdateScheduleUseCase(this.repository);

  Future<void> execute(
      String courseId, String scheduleId, Schedule updatedSchedule) {
    return repository.updateSchedule(courseId, scheduleId, updatedSchedule);
  }
}
