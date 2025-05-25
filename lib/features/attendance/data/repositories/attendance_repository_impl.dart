import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mytuition/features/courses/data/models/schedule_model.dart';
import 'package:mytuition/features/courses/domain/entities/schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final FirebaseFirestore _firestore;

  AttendanceRepositoryImpl(this._firestore);

  @override
  Future<List<Attendance>> getAttendanceByDate(
      String courseId, DateTime date) async {
    try {
      // Convert DateTime to a date string without time for comparison
      final dateOnly = DateTime(date.year, date.month, date.day);
      final nextDate = DateTime(date.year, date.month, date.day + 1);

      final snapshot = await _firestore
          .collection('attendance')
          .where('courseId', isEqualTo: courseId)
          .where('date', isGreaterThanOrEqualTo: dateOnly)
          .where('date', isLessThan: nextDate)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get attendance by date: $e');
    }
  }

  @override
  Future<List<Attendance>> getStudentAttendance(
      String courseId, String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('courseId', isEqualTo: courseId)
          .where('studentId', isEqualTo: studentId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get student attendance: $e');
    }
  }

  @override
  Future<List<Attendance>> getAllStudentAttendance(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all student attendance: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getCourseAttendanceStats(String courseId) async {
    try {
      // Get all attendance records for the course
      final snapshot = await _firestore
          .collection('attendance')
          .where('courseId', isEqualTo: courseId)
          .get();

      final attendanceRecords = snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
          .toList();

      // Get total count of students in the course
      final courseDoc =
          await _firestore.collection('classes').doc(courseId).get();
      final List<dynamic> enrolledStudents =
          courseDoc.data()?['students'] ?? [];

      int totalStudents = enrolledStudents.length;
      int totalDays = 0;
      Map<String, int> statusCounts = {
        'present': 0,
        'absent': 0,
        'late': 0,
        'excused': 0,
      };

      // Group by date to get unique class days
      Map<String, Set<String>> dateStudents = {};

      for (var record in attendanceRecords) {
        // Count by status
        switch (record.status) {
          case AttendanceStatus.present:
            statusCounts['present'] = (statusCounts['present'] ?? 0) + 1;
            break;
          case AttendanceStatus.absent:
            statusCounts['absent'] = (statusCounts['absent'] ?? 0) + 1;
            break;
          case AttendanceStatus.late:
            statusCounts['late'] = (statusCounts['late'] ?? 0) + 1;
            break;
          case AttendanceStatus.excused:
            statusCounts['excused'] = (statusCounts['excused'] ?? 0) + 1;
            break;
        }

        // Track unique dates
        String dateKey =
            '${record.date.year}-${record.date.month}-${record.date.day}';
        dateStudents[dateKey] = dateStudents[dateKey] ?? {};
        dateStudents[dateKey]!.add(record.studentId);
      }

      // Count unique class days
      totalDays = dateStudents.length;

      // Calculate attendance rate if there are students
      double attendanceRate = 0;
      if (totalStudents > 0 && totalDays > 0) {
        int possibleAttendances = totalStudents * totalDays;
        int actualAttendances =
            statusCounts['present']! + statusCounts['late']!;
        attendanceRate = actualAttendances / possibleAttendances;
      }

      return {
        'totalStudents': totalStudents,
        'totalDays': totalDays,
        'statusCounts': statusCounts,
        'attendanceRate': attendanceRate,
      };
    } catch (e) {
      throw Exception('Failed to get course attendance stats: $e');
    }
  }

  @override
  Future<void> recordAttendance(
      String courseId, String studentId, DateTime date, AttendanceStatus status,
      {String? remarks}) async {
    try {
      // Use compound ID for easier querying
      final dateString =
          '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
      final attendanceId = '$courseId-$studentId-$dateString';

      // Create attendance model
      final attendance = AttendanceModel(
        id: attendanceId,
        courseId: courseId,
        studentId: studentId,
        date: date,
        status: status,
        remarks: remarks,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('attendance')
          .doc(attendanceId)
          .set(attendance.toMap());
    } catch (e) {
      throw Exception('Failed to record attendance: $e');
    }
  }

  @override
  Future<void> recordBulkAttendance(String courseId, DateTime date,
      Map<String, AttendanceStatus> studentAttendances,
      {Map<String, String>? remarks}) async {
    try {
      // Use batch write for better performance
      final batch = _firestore.batch();
      final dateString =
          '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

      studentAttendances.forEach((studentId, status) {
        final attendanceId = '$courseId-$studentId-$dateString';

        final attendance = AttendanceModel(
          id: attendanceId,
          courseId: courseId,
          studentId: studentId,
          date: date,
          status: status,
          remarks: remarks?[studentId],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        batch.set(
          _firestore.collection('attendance').doc(attendanceId),
          attendance.toMap(),
        );
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to record bulk attendance: $e');
    }
  }

  @override
  Future<void> updateAttendance(String attendanceId, AttendanceStatus status,
      {String? remarks}) async {
    try {
      final updates = {
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (remarks != null) {
        updates['remarks'] = remarks;
      }

      await _firestore
          .collection('attendance')
          .doc(attendanceId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }

  @override
  Future<void> deleteAttendance(String attendanceId) async {
    try {
      await _firestore.collection('attendance').doc(attendanceId).delete();
    } catch (e) {
      throw Exception('Failed to delete attendance: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEnrolledStudents(
      String courseId) async {
    try {
      // Get the course document
      final courseDoc =
          await _firestore.collection('classes').doc(courseId).get();

      if (!courseDoc.exists) {
        throw Exception('Course not found');
      }

      // Get enrolled student IDs
      final List<dynamic> studentIds = courseDoc.data()?['students'] ?? [];

      if (studentIds.isEmpty) {
        return [];
      }

      // Get student details
      List<Map<String, dynamic>> students = [];

      for (var i = 0; i < studentIds.length; i += 10) {
        // Process in batches of 10 to avoid hitting Firestore limits
        final end = (i + 10 < studentIds.length) ? i + 10 : studentIds.length;
        final batch = studentIds.sublist(i, end);

        // Get student details from the users collection
        final snapshot = await _firestore
            .collection('users')
            .where('studentId', whereIn: batch)
            .get();

        final batchStudents = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'studentId': data['studentId'] ?? '',
            'name': data['name'] ?? '',
            'email': data['email'] ?? '',
            'grade': data['grade'],
          };
        }).toList();

        students.addAll(batchStudents);
      }

      return students;
    } catch (e) {
      throw Exception('Failed to get enrolled students: $e');
    }
  }

  Future<bool> hasNetworkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

// Add a storage key for last sync time
  static const String _lastSyncKey = 'last_attendance_sync';

// Add a method to get the last sync time
  Future<DateTime> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.now();
  }

// Update the last sync time
  Future<void> updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

// Check for unsynchronized attendance data
  Future<bool> hasUnsyncedData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('unsyncedAttendance');
  }

// Sync pending attendance records
  Future<void> syncPendingRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final unsyncedString = prefs.getString('unsyncedAttendance');

    if (unsyncedString != null) {
      try {
        final unsyncedData = jsonDecode(unsyncedString) as List;
        final batch = _firestore.batch();

        for (var data in unsyncedData) {
          final Map<String, dynamic> record = data as Map<String, dynamic>;
          final attendanceId = record['id'] as String;
          batch.set(
            _firestore.collection('attendance').doc(attendanceId),
            record,
          );
        }

        await batch.commit();
        await prefs.remove('unsyncedAttendance');
        await updateLastSyncTime();
      } catch (e) {
        // Handle sync errors
        print('Error syncing attendance: $e');
      }
    }

    // Always update sync time even if there's nothing to sync
    await updateLastSyncTime();
  }

  @override
  Future<List<Schedule>> getCourseSchedules(String courseId) async {
    try {
      final courseDoc =
          await _firestore.collection('classes').doc(courseId).get();

      if (!courseDoc.exists) {
        throw Exception('Course not found');
      }

      final List<dynamic> schedulesData = courseDoc.data()?['schedules'] ?? [];
      final courseData = courseDoc.data()!;
      final subject = courseData['subject'] as String;
      final grade = courseData['grade'] as int;

      return schedulesData.asMap().entries.map((entry) {
        final index = entry.key;
        final scheduleMap = entry.value as Map<String, dynamic>;

        // Use the courses ScheduleModel which supports replacement schedules
        return ScheduleModel.fromMap(
          scheduleMap,
          scheduleMap['id'] ?? '$courseId-schedule-$index',
          courseId: courseId,
          subject: subject,
          grade: grade,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get course schedules: $e');
    }
  }
}
