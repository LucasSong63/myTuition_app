import 'package:flutter/material.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/attendance/domain/entities/attendance.dart';

class ScannedStudentCard extends StatelessWidget {
  final String studentId;
  final String? studentName;
  final AttendanceStatus status;
  final VoidCallback? onDismiss;
  final VoidCallback? onChangeStatus;

  const ScannedStudentCard({
    Key? key,
    required this.studentId,
    this.studentName,
    required this.status,
    this.onDismiss,
    this.onChangeStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: _getStatusColor().withOpacity(0.2),
              child: Text(
                (studentName?.isNotEmpty == true)
                    ? studentName![0].toUpperCase()
                    : studentId.substring(0, 1),
                style: TextStyle(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Student info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName ?? 'Student',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    studentId,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Status chip
            Chip(
              label: Text(_getStatusText()),
              backgroundColor: _getStatusColor().withOpacity(0.2),
              labelStyle: TextStyle(
                color: _getStatusColor(),
                fontWeight: FontWeight.bold,
              ),
            ),

            // Actions
            if (onChangeStatus != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Change Status',
                onPressed: onChangeStatus,
              ),

            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Remove',
                onPressed: onDismiss,
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.late:
        return AppColors.warning;
      case AttendanceStatus.excused:
        return AppColors.accentTeal;
    }
  }
}
