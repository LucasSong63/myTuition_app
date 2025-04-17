import '../repositories/attendance_repository.dart';

class GetCourseAttendanceStatsUseCase {
  final AttendanceRepository repository;

  GetCourseAttendanceStatsUseCase(this.repository);

  Future<Map<String, dynamic>> execute(String courseId) {
    return repository.getCourseAttendanceStats(courseId);
  }
}
