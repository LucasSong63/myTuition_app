import '../repositories/attendance_repository.dart';

class GetEnrolledStudentsUseCase {
  final AttendanceRepository repository;

  GetEnrolledStudentsUseCase(this.repository);

  Future<List<Map<String, dynamic>>> execute(String courseId) {
    return repository.getEnrolledStudents(courseId);
  }
}
