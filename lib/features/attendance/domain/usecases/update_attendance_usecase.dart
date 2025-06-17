// lib/features/attendance/domain/usecases/update_attendance_usecase.dart

import '../entities/attendance.dart';
import '../repositories/attendance_repository.dart';

class UpdateAttendanceUseCase {
  final AttendanceRepository repository;

  UpdateAttendanceUseCase(this.repository);

  /// Update a single attendance record
  Future<void> execute(
    String attendanceId,
    AttendanceStatus status, {
    String? remarks,
  }) {
    return repository.updateAttendance(attendanceId, status, remarks: remarks);
  }

  /// Update multiple attendance records (for edit functionality)
  /// This is the main method used by EditAttendancePage
  Future<void> executeMultiple(
    String courseId,
    DateTime date,
    Map<String, AttendanceStatus> updatedAttendances,
    Map<String, String>? updatedRemarks,
  ) async {
    // Get existing attendance records to find document IDs
    final existingRecords =
        await repository.getAttendanceByDate(courseId, date);

    // Create a map of studentId -> attendance record for quick lookup
    final Map<String, Attendance> recordMap = {};
    for (var record in existingRecords) {
      recordMap[record.studentId] = record;
    }

    // Update each record individually
    for (var studentId in updatedAttendances.keys) {
      final existingRecord = recordMap[studentId];

      if (existingRecord != null) {
        final newStatus = updatedAttendances[studentId]!;
        final newRemarks = updatedRemarks?[studentId];

        // Only update if status actually changed
        if (existingRecord.status != newStatus ||
            existingRecord.remarks != newRemarks) {
          await repository.updateAttendance(
            existingRecord.id,
            newStatus,
            remarks: newRemarks,
          );
        }
      } else {
        // Log warning for missing record but don't fail
        print(
            'Warning: No existing attendance record found for student $studentId on $date');
      }
    }
  }

  /// Batch update for better performance (alternative implementation)
  Future<void> executeBatch(
    List<String> attendanceIds,
    List<AttendanceStatus> statuses,
    List<String?> remarks,
  ) async {
    if (attendanceIds.length != statuses.length ||
        attendanceIds.length != remarks.length) {
      throw ArgumentError('All lists must have the same length');
    }

    // Update each record
    for (int i = 0; i < attendanceIds.length; i++) {
      await repository.updateAttendance(
        attendanceIds[i],
        statuses[i],
        remarks: remarks[i],
      );
    }
  }
}
