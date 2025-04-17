import '../entities/attendance.dart';
import '../repositories/attendance_repository.dart';

class GetStudentAttendanceUseCase {
  final AttendanceRepository repository;

  GetStudentAttendanceUseCase(this.repository);

  Future<List<Attendance>> execute(String courseId, String studentId) {
    return repository.getStudentAttendance(courseId, studentId);
  }
}
