import 'package:mytuition/features/courses/domain/entities/schedule.dart';

import '../repositories/attendance_repository.dart';

class GetCourseSchedulesUseCase {
  final AttendanceRepository repository;

  GetCourseSchedulesUseCase(this.repository);

  Future<List<Schedule>> execute(String courseId) {
    return repository.getCourseSchedules(courseId);
  }
}
