// lib/features/attendance/data/repositories/attendance_repository_impl.dart
import 'dart:async';
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
      // NORMALIZE INPUT DATE
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final nextDate = normalizedDate.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('attendance')
          .where('courseId', isEqualTo: courseId)
          .where('date', isGreaterThanOrEqualTo: normalizedDate)
          .where('date', isLessThan: nextDate)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting attendance by date: $e');
      throw Exception('Failed to get attendance by date: $e');
    }
  }

  @override
  Future<void> recordBulkAttendance(String courseId, DateTime date,
      Map<String, AttendanceStatus> studentAttendances,
      {Map<String, String>? remarks}) async {
    try {
      // NORMALIZE DATE FOR CONSISTENT ID GENERATION
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final batch = _firestore.batch();
      final dateString =
          '${normalizedDate.year}${normalizedDate.month.toString().padLeft(2, '0')}${normalizedDate.day.toString().padLeft(2, '0')}';

      // FIXED: Extract schedule information for unique document ID
      String scheduleIdentifier = 'default';

      if (remarks?['_scheduleMeta'] != null) {
        try {
          final scheduleMeta =
              jsonDecode(remarks!['_scheduleMeta']!) as Map<String, dynamic>;

          // FIXED: Better schedule identifier extraction
          if (scheduleMeta['scheduleId'] != null) {
            final fullScheduleId = scheduleMeta['scheduleId'] as String;

            // Extract meaningful part from scheduleId
            // Examples:
            // "bahasa-malaysia-grade1-schedule-new" -> "schedulenew"
            // "bahasa-malaysia-grade1-schedule-0" -> "schedule0"
            if (fullScheduleId.contains('schedule')) {
              final parts = fullScheduleId.split('schedule');
              if (parts.length > 1) {
                scheduleIdentifier =
                    'schedule${parts.last.replaceAll('-', '')}';
              } else {
                scheduleIdentifier = 'schedule0';
              }
            } else {
              // Fallback: use last part of the ID
              final parts = fullScheduleId.split('-');
              scheduleIdentifier = parts.isNotEmpty ? parts.last : 'default';
            }
          } else if (scheduleMeta['scheduleIndex'] != null) {
            scheduleIdentifier = 'schedule${scheduleMeta['scheduleIndex']}';
          } else {
            // Use schedule time as identifier
            final startTime = scheduleMeta['scheduleStartTime'] as String?;
            if (startTime != null) {
              try {
                final time = DateTime.parse(startTime);
                scheduleIdentifier =
                    'time${time.hour.toString().padLeft(2, '0')}${time.minute.toString().padLeft(2, '0')}';
              } catch (e) {
                scheduleIdentifier =
                    'session${DateTime.now().millisecondsSinceEpoch % 10000}';
              }
            }
          }

          // Ensure identifier is safe for Firebase document ID
          scheduleIdentifier = scheduleIdentifier
              .replaceAll(' ', '')
              .replaceAll('.', '')
              .toLowerCase();

          // Limit length to avoid Firebase document ID limits (max 1500 chars, but keep it short)
          if (scheduleIdentifier.length > 15) {
            scheduleIdentifier = scheduleIdentifier.substring(0, 15);
          }
        } catch (e) {
          print('Error parsing schedule metadata for ID: $e');
          // Use timestamp as fallback to ensure uniqueness
          scheduleIdentifier =
              'session${DateTime.now().millisecondsSinceEpoch % 10000}';
        }
      }

      studentAttendances.forEach((studentId, status) {
        // FIXED: Include schedule identifier in document ID
        final attendanceId =
            '$courseId-$studentId-$dateString-$scheduleIdentifier';

        final attendanceData = {
          'courseId': courseId,
          'studentId': studentId,
          'date': normalizedDate, // Use normalized date
          'status': status.toString().split('.').last,
          'remarks': remarks?[studentId],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add schedule metadata if present
        if (remarks?['_scheduleMeta'] != null) {
          try {
            final scheduleMeta =
                jsonDecode(remarks!['_scheduleMeta']!) as Map<String, dynamic>;
            attendanceData['scheduleMetadata'] = scheduleMeta;
          } catch (e) {
            print('Error parsing schedule metadata: $e');
          }
        }

        batch.set(
          _firestore.collection('attendance').doc(attendanceId),
          attendanceData,
        );
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to record bulk attendance: $e');
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
      int totalSessions = 0; // FIXED: Changed from totalDays to totalSessions
      Map<String, int> statusCounts = {
        'present': 0,
        'absent': 0,
        'late': 0,
        'excused': 0,
      };

      // FIXED: Group by date AND schedule to count unique sessions
      Map<String, Set<String>> sessionIdentifiers = {};

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

        // FIXED: Track unique sessions using date + schedule metadata
        String dateKey =
            '${record.date.year}-${record.date.month}-${record.date.day}';

        // Try to extract schedule ID from the attendance record
        String scheduleKey = 'default'; // fallback

        // Note: This assumes you store schedule metadata in the attendance record
        // You may need to adjust this based on your actual data structure
        // For now, we'll use the record ID pattern to identify unique sessions
        if (record.id.contains('-')) {
          List<String> idParts = record.id.split('-');
          if (idParts.length >= 3) {
            // If the ID follows pattern: courseId-studentId-date-scheduleId
            // Extract some identifier for the session
            scheduleKey = idParts.length > 3 ? idParts[3] : 'session1';
          }
        }

        String sessionIdentifier = '${dateKey}_$scheduleKey';
        sessionIdentifiers[sessionIdentifier] =
            sessionIdentifiers[sessionIdentifier] ?? {};
        sessionIdentifiers[sessionIdentifier]!.add(record.studentId);
      }

      // FIXED: Count unique sessions instead of unique days
      totalSessions = sessionIdentifiers.length;

      // Calculate attendance rate if there are students and sessions
      double attendanceRate = 0;
      if (totalStudents > 0 && totalSessions > 0) {
        int possibleAttendances = totalStudents * totalSessions;
        int actualAttendances =
            statusCounts['present']! + statusCounts['late']!;
        attendanceRate = actualAttendances / possibleAttendances;
      }

      return {
        'totalStudents': totalStudents,
        'totalSessions': totalSessions, // FIXED: Changed from totalDays
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
      {String? remarks, String? scheduleId}) async {
    try {
      // FIXED: Include schedule information in single attendance record
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final dateString =
          '${normalizedDate.year}${normalizedDate.month.toString().padLeft(2, '0')}${normalizedDate.day.toString().padLeft(2, '0')}';

      // Use provided scheduleId or create default
      String scheduleIdentifier = 'default';
      if (scheduleId != null) {
        if (scheduleId.contains('schedule')) {
          final parts = scheduleId.split('schedule');
          if (parts.length > 1) {
            scheduleIdentifier = 'schedule${parts.last.replaceAll('-', '')}';
          } else {
            scheduleIdentifier = 'schedule0';
          }
        } else {
          final parts = scheduleId.split('-');
          scheduleIdentifier = parts.isNotEmpty ? parts.last : 'default';
        }
      }

      final attendanceId =
          '$courseId-$studentId-$dateString-$scheduleIdentifier';

      // Create attendance model
      final attendance = AttendanceModel(
        id: attendanceId,
        courseId: courseId,
        studentId: studentId,
        date: normalizedDate,
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

  @override
  Future<bool> hasAttendanceForSchedule(
      String courseId, DateTime date, String scheduleId) async {
    try {
      // Convert DateTime to a date string without time for comparison
      final dateOnly = DateTime(date.year, date.month, date.day);
      final nextDate = DateTime(date.year, date.month, date.day + 1);

      final snapshot = await _firestore
          .collection('attendance')
          .where('courseId', isEqualTo: courseId)
          .where('date', isGreaterThanOrEqualTo: dateOnly)
          .where('date', isLessThan: nextDate)
          .where('scheduleMetadata.scheduleId', isEqualTo: scheduleId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking schedule attendance: $e');
      throw Exception('Failed to check schedule attendance: $e');
    }
  }

  @override
  Future<int> getScheduleAttendanceCount(
      String courseId, DateTime date, String scheduleId) async {
    try {
      // Convert DateTime to a date string without time for comparison
      final dateOnly = DateTime(date.year, date.month, date.day);
      final nextDate = DateTime(date.year, date.month, date.day + 1);

      final snapshot = await _firestore
          .collection('attendance')
          .where('courseId', isEqualTo: courseId)
          .where('date', isGreaterThanOrEqualTo: dateOnly)
          .where('date', isLessThan: nextDate)
          .where('scheduleMetadata.scheduleId', isEqualTo: scheduleId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting schedule attendance count: $e');
      throw Exception('Failed to get schedule attendance count: $e');
    }
  }

  @override
  Future<Map<String, List<Attendance>>> getAttendanceInDateRange(
      String courseId, DateTime startDate, DateTime endDate) async {
    try {
      // Ensure we're working with date-only values for consistent querying
      final startDateOnly =
          DateTime(startDate.year, startDate.month, startDate.day);
      final endDateOnly =
          DateTime(endDate.year, endDate.month, endDate.day + 1);

      print(
          "OPTIMIZED: Querying attendance for course $courseId from $startDateOnly to $endDateOnly");

      // OPTIMIZED: Single query with proper compound indexing
      // Firestore index should be created on: courseId (Ascending), date (Ascending)
      final snapshot = await _firestore
          .collection('attendance')
          .where('courseId', isEqualTo: courseId)
          .where('date', isGreaterThanOrEqualTo: startDateOnly)
          .where('date', isLessThan: endDateOnly)
          .orderBy('date', descending: true) // Most recent first
          .get();

      print(
          "OPTIMIZED: Found ${snapshot.docs.length} attendance records in single query");

      // Group attendance records by date string
      final Map<String, List<Attendance>> groupedAttendance = {};

      for (var doc in snapshot.docs) {
        final attendance = AttendanceModel.fromMap(doc.data(), doc.id);
        final dateKey =
            '${attendance.date.year}-${attendance.date.month.toString().padLeft(2, '0')}-${attendance.date.day.toString().padLeft(2, '0')}';

        groupedAttendance[dateKey] = groupedAttendance[dateKey] ?? [];
        groupedAttendance[dateKey]!.add(attendance);
      }

      print("OPTIMIZED: Grouped into ${groupedAttendance.length} unique dates");

      // Cache the result for faster subsequent access
      await _cacheAttendanceRange(
          courseId, startDateOnly, endDateOnly, groupedAttendance);

      return groupedAttendance;
    } catch (e) {
      print('Error getting attendance in date range: $e');

      // Try to get cached data as fallback
      final cachedData =
          await _getCachedAttendanceRange(courseId, startDate, endDate);
      if (cachedData.isNotEmpty) {
        print('Returning cached attendance data as fallback');
        return cachedData;
      }

      throw Exception('Failed to get attendance in date range: $e');
    }
  }

  // FIXED: Cache declaration to store the correct nested map type
  final Map<String, Map<String, Map<String, dynamic>>> _scheduleStatusCache =
      {};

  // FIXED: Removed nullable return type to match interface
  @override
  Future<Map<String, Map<String, dynamic>>> getMultipleScheduleAttendanceStatus(
      String courseId, DateTime date, List<String> scheduleIds) async {
    try {
      // Normalize date for consistent querying
      final dateOnly = DateTime(date.year, date.month, date.day);
      final nextDate = DateTime(date.year, date.month, date.day + 1);

      print('DEBUG: Checking attendance for course: $courseId');
      print('DEBUG: Date range: $dateOnly to $nextDate');
      print('DEBUG: Schedule IDs: $scheduleIds');

      // FIX: Query all attendance records for the course and date
      final snapshot = await _firestore
          .collection('attendance')
          .where('courseId', isEqualTo: courseId)
          .where('date', isGreaterThanOrEqualTo: dateOnly)
          .where('date', isLessThan: nextDate)
          .get();

      print('DEBUG: Found ${snapshot.docs.length} attendance records');

      // Group by schedule ID
      final Map<String, List<Attendance>> scheduleAttendance = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // FIX: Check multiple possible locations for schedule ID
        String? scheduleId;

        // First, try to get from scheduleMetadata
        final scheduleMetadata =
            data['scheduleMetadata'] as Map<String, dynamic>?;
        if (scheduleMetadata != null) {
          scheduleId = scheduleMetadata['scheduleId'] as String?;
        }

        // If not found, try legacy scheduleIndex approach
        if (scheduleId == null) {
          final scheduleIndex = data['scheduleIndex'] as int?;
          if (scheduleIndex != null) {
            scheduleId = '$courseId-schedule-$scheduleIndex';
          }
        }

        print('DEBUG: Document ${doc.id} has scheduleId: $scheduleId');

        if (scheduleId != null && scheduleIds.contains(scheduleId)) {
          scheduleAttendance[scheduleId] = scheduleAttendance[scheduleId] ?? [];
          scheduleAttendance[scheduleId]!
              .add(AttendanceModel.fromMap(data, doc.id));
        }
      }

      // Build status map for all requested schedule IDs
      final Map<String, Map<String, dynamic>> statusMap = {};

      for (String scheduleId in scheduleIds) {
        final records = scheduleAttendance[scheduleId] ?? [];
        statusMap[scheduleId] = {
          'isTaken': records.isNotEmpty,
          'count': records.length,
          'records': records,
        };

        print(
            'DEBUG: Schedule $scheduleId - isTaken: ${records.isNotEmpty}, count: ${records.length}');
      }

      return statusMap;
    } catch (e) {
      print('Error getting multiple schedule attendance status: $e');
      // Return empty map with default false values for all schedule IDs
      final Map<String, Map<String, dynamic>> emptyStatusMap = {};
      for (String scheduleId in scheduleIds) {
        emptyStatusMap[scheduleId] = {
          'isTaken': false,
          'count': 0,
          'records': <Attendance>[],
        };
      }
      return emptyStatusMap;
    }
  }

  Future<void> _cacheAttendanceRange(
    String courseId,
    DateTime startDate,
    DateTime endDate,
    Map<String, List<Attendance>> attendanceMap,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key =
          'attendance_range_${courseId}_${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}';

      // Convert to JSON-serializable format
      final Map<String, dynamic> serializedData = {};

      attendanceMap.forEach((dateKey, records) {
        serializedData[dateKey] = records
            .map((record) => {
                  'id': record.id,
                  'courseId': record.courseId,
                  'studentId': record.studentId,
                  'date': record.date.millisecondsSinceEpoch,
                  'status': record.status.toString().split('.').last,
                  'remarks': record.remarks,
                  'createdAt': record.createdAt.millisecondsSinceEpoch,
                  'updatedAt': record.updatedAt.millisecondsSinceEpoch,
                })
            .toList();
      });

      await prefs.setString(
          key,
          jsonEncode({
            'data': serializedData,
            'cachedAt': DateTime.now().millisecondsSinceEpoch,
          }));
    } catch (e) {
      print('Error caching attendance range: $e');
      // Don't rethrow as caching is not critical
    }
  }

  Future<Map<String, List<Attendance>>> _getCachedAttendanceRange(
    String courseId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key =
          'attendance_range_${courseId}_${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}';
      final cached = prefs.getString(key);

      if (cached != null) {
        final Map<String, dynamic> cacheEntry =
            jsonDecode(cached) as Map<String, dynamic>;
        final cachedAt =
            DateTime.fromMillisecondsSinceEpoch(cacheEntry['cachedAt'] as int);

        // Check if cache is still valid (less than 1 hour old)
        if (DateTime.now().difference(cachedAt).inHours < 1) {
          final Map<String, dynamic> rawData =
              cacheEntry['data'] as Map<String, dynamic>;
          final Map<String, List<Attendance>> result = {};

          rawData.forEach((dateKey, recordsList) {
            final List<dynamic> records = recordsList as List<dynamic>;
            result[dateKey] = records.map<Attendance>((item) {
              final Map<String, dynamic> data =
                  Map<String, dynamic>.from(item as Map);
              return Attendance(
                id: data['id'] as String,
                courseId: data['courseId'] as String,
                studentId: data['studentId'] as String,
                date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
                status: _parseAttendanceStatus(data['status'] as String),
                remarks: data['remarks'] as String?,
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                    data['createdAt'] as int),
                updatedAt: DateTime.fromMillisecondsSinceEpoch(
                    data['updatedAt'] as int),
              );
            }).toList();
          });

          return result;
        }
      }
    } catch (e) {
      print('Error getting cached attendance range: $e');
    }
    return {};
  }

  // Helper to parse attendance status
  AttendanceStatus _parseAttendanceStatus(String status) {
    switch (status) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'excused':
        return AttendanceStatus.excused;
      default:
        return AttendanceStatus.absent;
    }
  }

  // PHASE 3.2: Clean up old cache entries
  Future<void> cleanupOldCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith('attendance_range_') ||
            key.startsWith('past_7_days_attendance_')) {
          final value = prefs.getString(key);
          if (value != null) {
            try {
              final Map<String, dynamic> cacheEntry =
                  jsonDecode(value) as Map<String, dynamic>;
              final cachedAt = DateTime.fromMillisecondsSinceEpoch(
                  cacheEntry['cachedAt'] as int);

              // Remove cache entries older than 24 hours
              if (DateTime.now().difference(cachedAt).inHours > 24) {
                await prefs.remove(key);
                print('Removed old cache entry: $key');
              }
            } catch (e) {
              // Invalid cache entry, remove it
              await prefs.remove(key);
            }
          }
        }
      }
    } catch (e) {
      print('Error cleaning up old cache: $e');
    }
  }
}
