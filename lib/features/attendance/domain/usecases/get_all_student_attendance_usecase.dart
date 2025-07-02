import '../entities/attendance.dart';
import '../repositories/attendance_repository.dart';

class GetAllStudentAttendanceUseCase {
  final AttendanceRepository repository;

  GetAllStudentAttendanceUseCase(this.repository);

  Future<List<Attendance>> execute(String studentId) {
    return repository.getAllStudentAttendance(studentId);
  }
}
