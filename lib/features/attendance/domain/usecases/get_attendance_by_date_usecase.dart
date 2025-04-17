import '../entities/attendance.dart';
import '../repositories/attendance_repository.dart';

class GetAttendanceByDateUseCase {
  final AttendanceRepository repository;

  GetAttendanceByDateUseCase(this.repository);

  Future<List<Attendance>> execute(String courseId, DateTime date) {
    return repository.getAttendanceByDate(courseId, date);
  }
}
