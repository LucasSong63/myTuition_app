import '../entities/attendance.dart';
import '../repositories/attendance_repository.dart';

class RecordBulkAttendanceUseCase {
  final AttendanceRepository repository;

  RecordBulkAttendanceUseCase(this.repository);

  Future<void> execute(String courseId, DateTime date,
      Map<String, AttendanceStatus> studentAttendances,
      {Map<String, String>? remarks}) {
    return repository.recordBulkAttendance(
      courseId,
      date,
      studentAttendances,
      remarks: remarks,
    );
  }
}
