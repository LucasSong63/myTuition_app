import '../repositories/attendance_repository.dart';

class CheckScheduleAttendanceUseCase {
  final AttendanceRepository repository;

  CheckScheduleAttendanceUseCase(this.repository);

  /// Check if attendance has been taken for a specific schedule
  /// Returns true if attendance exists for the given schedule
  Future<bool> execute(String courseId, DateTime date, String scheduleId) {
    return repository.hasAttendanceForSchedule(courseId, date, scheduleId);
  }
}
