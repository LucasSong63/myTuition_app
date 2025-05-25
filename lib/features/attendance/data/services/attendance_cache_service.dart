import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mytuition/features/attendance/domain/entities/attendance.dart';

/// Service for caching attendance data for offline use
class AttendanceCacheService {
  static const String _qrScannedCacheKey = 'qr_scanned_attendance_cache';

  /// Caches scanned students for a specific course and date
  Future<void> cacheScannedStudents({
    required String courseId,
    required DateTime date,
    required Map<String, AttendanceStatus> studentAttendances,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing cache or create new
      final cache = prefs.getString(_qrScannedCacheKey);
      final Map<String, dynamic> cacheData =
          cache != null ? json.decode(cache) as Map<String, dynamic> : {};

      // Create key for this course and date
      final dateStr = '${date.year}-${date.month}-${date.day}';
      final cacheKey = '$courseId-$dateStr';

      // Create serializable data
      final Map<String, String> serializedAttendances = {};
      studentAttendances.forEach((id, status) {
        serializedAttendances[id] = status.toString().split('.').last;
      });

      // Update cache
      cacheData[cacheKey] = {
        'courseId': courseId,
        'date': date.millisecondsSinceEpoch,
        'studentAttendances': serializedAttendances,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Save updated cache
      await prefs.setString(_qrScannedCacheKey, json.encode(cacheData));
    } catch (e) {
      print('Error caching scanned students: $e');
    }
  }

  /// Gets cached scanned students for a specific course and date
  Future<Map<String, AttendanceStatus>> getCachedScannedStudents({
    required String courseId,
    required DateTime date,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cache = prefs.getString(_qrScannedCacheKey);

      if (cache == null) return {};

      final Map<String, dynamic> cacheData =
          json.decode(cache) as Map<String, dynamic>;

      // Create key for this course and date
      final dateStr = '${date.year}-${date.month}-${date.day}';
      final cacheKey = '$courseId-$dateStr';

      if (!cacheData.containsKey(cacheKey)) return {};

      // Deserialize attendance data
      final Map<String, dynamic> cachedItem =
          cacheData[cacheKey] as Map<String, dynamic>;
      final Map<String, dynamic> serializedAttendances =
          cachedItem['studentAttendances'] as Map<String, dynamic>;

      // Convert back to enum
      final Map<String, AttendanceStatus> result = {};
      serializedAttendances.forEach((id, statusStr) {
        result[id] = _parseAttendanceStatus(statusStr as String);
      });

      return result;
    } catch (e) {
      print('Error getting cached scanned students: $e');
      return {};
    }
  }

  /// Checks if there is any unsynced scanned data
  Future<bool> hasUnsyncedScannedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_qrScannedCacheKey);
    } catch (e) {
      return false;
    }
  }

  /// Removes cached data after successful sync
  Future<void> clearCachedData({
    String? courseId,
    DateTime? date,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // If specific course and date provided, only clear that entry
      if (courseId != null && date != null) {
        final cache = prefs.getString(_qrScannedCacheKey);
        if (cache == null) return;

        final Map<String, dynamic> cacheData =
            json.decode(cache) as Map<String, dynamic>;
        final dateStr = '${date.year}-${date.month}-${date.day}';
        final cacheKey = '$courseId-$dateStr';

        if (cacheData.containsKey(cacheKey)) {
          cacheData.remove(cacheKey);
          await prefs.setString(_qrScannedCacheKey, json.encode(cacheData));
        }
      } else {
        // Clear all cached data
        await prefs.remove(_qrScannedCacheKey);
      }
    } catch (e) {
      print('Error clearing cached data: $e');
    }
  }

  /// Helper method to parse status string to enum
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
}
