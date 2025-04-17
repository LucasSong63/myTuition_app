import '../repositories/course_repository.dart';

class DeleteScheduleUseCase {
  final CourseRepository repository;

  DeleteScheduleUseCase(this.repository);

  Future<void> execute(String courseId, String scheduleId) {
    return repository.deleteSchedule(courseId, scheduleId);
  }
}
