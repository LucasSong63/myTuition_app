import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/attendance/presentation/bloc/attendance_event.dart';
import '../../domain/entities/attendance.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_state.dart';

class StudentAttendanceDetailsPage extends StatefulWidget {
  final Map<String, dynamic> student;
  final String courseName;
  final String courseId; // Added courseId parameter

  const StudentAttendanceDetailsPage({
    Key? key,
    required this.student,
    required this.courseName,
    required this.courseId, // Make it required
  }) : super(key: key);

  @override
  State<StudentAttendanceDetailsPage> createState() =>
      _StudentAttendanceDetailsPageState();
}

class _StudentAttendanceDetailsPageState
    extends State<StudentAttendanceDetailsPage> {
  @override
  void initState() {
    super.initState();

    // Ensure we have attendance data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AttendanceBloc>().state;
      // If the state doesn't have the student attendance loaded, load it
      if (!(state is StudentAttendanceLoaded &&
          state.studentId == widget.student['studentId'])) {
        context.read<AttendanceBloc>().add(LoadStudentAttendanceEvent(
              courseId: widget.courseId, // Use the provided courseId
              studentId: widget.student['studentId'] as String,
            ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student['name']} Attendance'),
      ),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state is AttendanceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StudentAttendanceLoaded) {
            final attendanceRecords = state.attendanceRecords;

            if (attendanceRecords.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No attendance records found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This student has no attendance records yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context
                            .read<AttendanceBloc>()
                            .add(LoadStudentAttendanceEvent(
                              courseId: widget.courseId,
                              // Use the provided courseId
                              studentId: widget.student['studentId'] as String,
                            ));
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            child: Text(
                              widget.student['name'].toString().isNotEmpty
                                  ? widget.student['name']
                                      .toString()[0]
                                      .toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.student['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Student ID: ${widget.student['studentId']}',
                                  style: TextStyle(
                                    color: AppColors.textMedium,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Course: ${widget.courseName}',
                                  style: TextStyle(
                                    color: AppColors.textMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Attendance statistics
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Attendance Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAttendanceStats(attendanceRecords),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Attendance history
                  const Text(
                    'Attendance History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...attendanceRecords
                      .map((record) => _buildAttendanceRecord(record))
                      .toList(),
                ],
              ),
            );
          }

          if (state is AttendanceError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<AttendanceBloc>()
                          .add(LoadStudentAttendanceEvent(
                            courseId:
                                widget.courseId, // Use the provided courseId
                            studentId: widget.student['studentId'] as String,
                          ));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Default state - not loaded yet
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading attendance data...'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttendanceStats(List<Attendance> records) {
    // Count attendance by status
    int present = 0;
    int absent = 0;
    int late = 0;
    int excused = 0;

    for (var record in records) {
      switch (record.status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.late:
          late++;
          break;
        case AttendanceStatus.excused:
          excused++;
          break;
      }
    }

    final total = records.length;
    final attendanceRate = total > 0 ? (present + late) / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard('Present', present, total, AppColors.success),
            _buildStatCard('Late', late, total, AppColors.warning),
            _buildStatCard('Absent', absent, total, AppColors.error),
            _buildStatCard('Excused', excused, total, AppColors.accentTeal),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Overall Attendance: ',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            Text(
              '${(attendanceRate * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getAttendanceRateColor(attendanceRate),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          Text(
            '${(percentage * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecord(Attendance record) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (record.status) {
      case AttendanceStatus.present:
        statusColor = AppColors.success;
        statusText = 'Present';
        statusIcon = Icons.check_circle;
        break;
      case AttendanceStatus.absent:
        statusColor = AppColors.error;
        statusText = 'Absent';
        statusIcon = Icons.cancel;
        break;
      case AttendanceStatus.late:
        statusColor = AppColors.warning;
        statusText = 'Late';
        statusIcon = Icons.watch_later;
        break;
      case AttendanceStatus.excused:
        statusColor = AppColors.accentTeal;
        statusText = 'Excused';
        statusIcon = Icons.assignment_late;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          statusIcon,
          color: statusColor,
          size: 28,
        ),
        title: Text(
          dateFormat.format(record.date),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: record.remarks != null && record.remarks!.isNotEmpty
            ? Text(
                'Remarks: ${record.remarks}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMedium,
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getAttendanceRateColor(double rate) {
    if (rate >= 0.9) {
      return AppColors.success;
    } else if (rate >= 0.75) {
      return AppColors.accentTeal;
    } else if (rate >= 0.6) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }
}
