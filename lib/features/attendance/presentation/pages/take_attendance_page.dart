import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/features/courses/domain/entities/schedule.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/core/widgets/loading_overlay.dart';
import 'package:mytuition/features/attendance/data/services/attendance_cache_service.dart';
import 'package:mytuition/features/attendance/presentation/pages/qr_scanner_page.dart';
import '../../domain/entities/attendance.dart';

import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

enum AttendanceMode {
  general,
  session,
}

class TakeAttendancePage extends StatefulWidget {
  final String courseId;
  final String courseName;

  const TakeAttendancePage({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  State<TakeAttendancePage> createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  // Always use today's date - no date editing allowed
  final DateTime _attendanceDate = DateTime.now();
  Map<String, AttendanceStatus> _studentAttendances = {};
  Map<String, String> _studentRemarks = {};
  bool _isSubmitting = false;

  // Attendance mode selection
  AttendanceMode _attendanceMode = AttendanceMode.general;

  // Batch edit mode
  bool _batchEditMode = false;
  Set<String> _selectedStudents = {};

  // Schedule selection (only for session mode)
  List<Schedule> _schedules = [];
  int? _selectedScheduleIndex;

  // Search
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isSearching = false;

  // Cache service for offline support
  final AttendanceCacheService _cacheService = AttendanceCacheService();

  // Track if there are existing records
  bool _hasExistingRecords = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStudents);

    // Load data for today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodayData();
      _loadCachedScannedStudents();

      // Check connection status
      context.read<AttendanceBloc>().add(CheckConnectionStatusEvent());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTodayData() {
    // Load enrolled students
    context.read<AttendanceBloc>().add(
          LoadEnrolledStudentsEvent(courseId: widget.courseId),
        );

    // Load existing attendance for today
    context.read<AttendanceBloc>().add(
          LoadAttendanceByDateEvent(
            courseId: widget.courseId,
            date: _attendanceDate,
          ),
        );

    // Load course schedules for session selection
    context.read<AttendanceBloc>().add(
          LoadCourseSchedulesEvent(courseId: widget.courseId),
        );
  }

  Future<void> _loadCachedScannedStudents() async {
    final cachedAttendances = await _cacheService.getCachedScannedStudents(
      courseId: widget.courseId,
      date: _attendanceDate,
    );

    if (cachedAttendances.isNotEmpty) {
      setState(() {
        _studentAttendances.addAll(cachedAttendances);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loaded cached QR scan data from offline storage'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _filterStudents() {
    if (context.read<AttendanceBloc>().state is EnrolledStudentsLoaded) {
      final state =
          context.read<AttendanceBloc>().state as EnrolledStudentsLoaded;

      setState(() {
        if (_searchController.text.isEmpty) {
          _filteredStudents = state.students;
          _isSearching = false;
        } else {
          _isSearching = true;
          _filteredStudents = state.students.where((student) {
            final name = student['name'].toString().toLowerCase();
            final id = student['studentId'].toString().toLowerCase();
            final query = _searchController.text.toLowerCase();
            return name.contains(query) || id.contains(query);
          }).toList();
        }
      });
    }
  }

  Future<void> _scanStudentQRCodes() async {
    final currentStudents = _filteredStudents.isEmpty
        ? context.read<AttendanceBloc>().state is EnrolledStudentsLoaded
            ? (context.read<AttendanceBloc>().state as EnrolledStudentsLoaded)
                .students
            : <Map<String, dynamic>>[]
        : _filteredStudents;

    final enrolledStudentsMap =
        currentStudents.fold<Map<String, Map<String, dynamic>>>(
      {},
      (map, student) =>
          map..putIfAbsent(student['studentId'] as String, () => student),
    );

    final result = await Navigator.push<Map<String, AttendanceStatus>>(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerPage(
          enrolledStudents: enrolledStudentsMap,
          initialAttendances: _studentAttendances,
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _studentAttendances.addAll(result);
      });

      // Cache the scanned results
      await _cacheService.cacheScannedStudents(
        courseId: widget.courseId,
        date: _attendanceDate,
        studentAttendances: result,
      );

      final count = result.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count students marked via QR scan'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _submitAttendance() {
    if (_studentAttendances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No attendance data to submit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if this will update existing records
    if (_hasExistingRecords) {
      _showUpdateConfirmation();
      return;
    }

    _actuallySubmitAttendance();
  }

  void _showUpdateConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Update Attendance'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance records already exist for today.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Replacement Behavior',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Submitting will replace ALL existing attendance records for this course on ${DateFormat('MMM d, yyyy').format(_attendanceDate)}.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Do you want to continue?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _actuallySubmitAttendance();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Update Attendance'),
          ),
        ],
      ),
    );
  }

  void _actuallySubmitAttendance() {
    setState(() {
      _isSubmitting = true;
    });

    // Filter out empty remarks
    final Map<String, String> nonEmptyRemarks = {};
    _studentRemarks.forEach((key, value) {
      if (value.trim().isNotEmpty) {
        nonEmptyRemarks[key] = value;
      }
    });

    // Cache QR scanned data for offline use
    _cacheService.cacheScannedStudents(
      courseId: widget.courseId,
      date: _attendanceDate,
      studentAttendances: _studentAttendances,
    );

    // Submit based on attendance mode
    if (_attendanceMode == AttendanceMode.session &&
        _selectedScheduleIndex != null) {
      context.read<AttendanceBloc>().add(
            RecordScheduledAttendanceEvent(
              courseId: widget.courseId,
              date: _attendanceDate,
              scheduleIndex: _selectedScheduleIndex!,
              studentAttendances: _studentAttendances,
              remarks: nonEmptyRemarks.isNotEmpty ? nonEmptyRemarks : null,
            ),
          );
    } else {
      context.read<AttendanceBloc>().add(
            RecordBulkAttendanceEvent(
              courseId: widget.courseId,
              date: _attendanceDate,
              studentAttendances: _studentAttendances,
              remarks: nonEmptyRemarks.isNotEmpty ? nonEmptyRemarks : null,
            ),
          );
    }
  }

  // Toggle batch edit mode
  void _toggleBatchMode() {
    setState(() {
      _batchEditMode = !_batchEditMode;
      if (!_batchEditMode) {
        _selectedStudents.clear();
      }
    });
  }

  // Mark all students with the same status
  void _markAllStudents(AttendanceStatus status) {
    final state = context.read<AttendanceBloc>().state;

    if (state is EnrolledStudentsLoaded) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Bulk Action'),
          content: Text(
            'Are you sure you want to mark all ${state.students.length} students as ${status.toString().split('.').last}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  for (var student in state.students) {
                    final studentId = student['studentId'] as String;
                    _studentAttendances[studentId] = status;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Marked all students as ${status.toString().split('.').last}'),
                  ),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    }
  }

  // Apply batch status to selected students
  void _applyBatchStatus(AttendanceStatus status) {
    setState(() {
      for (var studentId in _selectedStudents) {
        _studentAttendances[studentId] = status;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Marked ${_selectedStudents.length} students as ${status.toString().split('.').last}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              for (var studentId in _selectedStudents) {
                _studentAttendances.remove(studentId);
              }
            });
          },
        ),
      ),
    );
  }

  // Build offline sync status
  Widget _buildSyncStatus() {
    final state = context.watch<AttendanceBloc>().state;

    if (state is AttendanceOfflineMode) {
      return Container(
        padding: EdgeInsets.all(3.w),
        color:
            state.hasUnsynced ? Colors.amber.shade100 : Colors.green.shade100,
        child: Row(
          children: [
            Icon(
              state.hasUnsynced ? Icons.sync_problem : Icons.check_circle,
              size: 20,
              color: state.hasUnsynced
                  ? Colors.amber.shade700
                  : Colors.green.shade700,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                state.hasUnsynced
                    ? 'Working offline - changes will sync when online'
                    : 'Last synced: ${DateFormat('MMM dd, hh:mm a').format(state.lastSynced)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: state.hasUnsynced
                      ? Colors.amber.shade700
                      : Colors.green.shade700,
                ),
              ),
            ),
            if (state.hasUnsynced)
              TextButton.icon(
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Sync Now'),
                onPressed: () {
                  context.read<AttendanceBloc>().add(SyncAttendanceDataEvent());
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Take Attendance'),
        actions: [
          IconButton(
            icon: Icon(_batchEditMode ? Icons.done : Icons.edit),
            tooltip: _batchEditMode ? 'Exit Batch Mode' : 'Batch Edit Mode',
            onPressed: _toggleBatchMode,
          ),
        ],
      ),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
            setState(() {
              _isSubmitting = false;
            });
          }

          if (state is AttendanceRecordSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            setState(() {
              _isSubmitting = false;
            });

            // Clear cache after successful submission
            _cacheService.clearCachedData(
              courseId: widget.courseId,
              date: _attendanceDate,
            );
          }

          // Handle existing attendance data
          if (state is AttendanceByDateLoaded) {
            setState(() {
              _hasExistingRecords = state.attendanceRecords.isNotEmpty;
            });

            if (state.attendanceRecords.isNotEmpty) {
              // Update the student attendances map with existing data
              final existingAttendances = <String, AttendanceStatus>{};
              final existingRemarks = <String, String>{};

              for (var record in state.attendanceRecords) {
                existingAttendances[record.studentId] = record.status;
                if (record.remarks != null && record.remarks!.isNotEmpty) {
                  existingRemarks[record.studentId] = record.remarks!;
                }
              }

              setState(() {
                _studentAttendances.addAll(existingAttendances);
                _studentRemarks.addAll(existingRemarks);
              });
            }
          }

          // Handle loaded schedules
          if (state is CourseSchedulesLoaded) {
            setState(() {
              _schedules = state.schedules;
            });
          }

          // Update filtered students when loaded
          if (state is EnrolledStudentsLoaded) {
            setState(() {
              _filteredStudents = state.students;
            });
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: _isSubmitting,
            message: 'Saving attendance records...',
            child: _buildContent(state),
          );
        },
      ),
    );
  }

  Widget _buildContent(AttendanceState state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Course and date info
          _buildHeaderInfo(),

          // Sync status
          _buildSyncStatus(),

          // Replacement behavior warning
          _buildReplacementWarning(),

          // Attendance mode selector
          _buildAttendanceModeSelector(),

          // Schedule selector (only for session mode)
          if (_attendanceMode == AttendanceMode.session &&
              _schedules.isNotEmpty)
            _buildScheduleSelector(),

          // Search bar (only when not in batch mode)
          if (!_batchEditMode) _buildSearchBar(),

          // QR Scanner and Bulk actions section
          _buildActionsSection(),

          // Students list
          _buildStudentsList(state),

          // Batch actions panel (when in batch mode)
          if (_batchEditMode && _selectedStudents.isNotEmpty)
            _buildBatchActionsPanel(),

          // Submit button
          if (!_batchEditMode) _buildSubmitButton(),

          // Extra bottom padding for better scrolling
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.school, color: AppColors.primaryBlue, size: 28),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.courseName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Course ID: ${widget.courseId}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasExistingRecords)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.orange[700]),
                      SizedBox(width: 1.w),
                      Text(
                        'Updating',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.today, color: AppColors.primaryBlue),
                SizedBox(width: 3.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Date',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_attendanceDate),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplacementWarning() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Policy',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Taking attendance multiple times for the same course on the same day will replace previous records.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceModeSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Mode',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: RadioListTile<AttendanceMode>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'General',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                  subtitle: Text(
                    'Daily roll call',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  value: AttendanceMode.general,
                  groupValue: _attendanceMode,
                  onChanged: (value) {
                    setState(() {
                      _attendanceMode = value!;
                      _selectedScheduleIndex = null;
                    });
                  },
                  activeColor: AppColors.primaryBlue,
                ),
              ),
              Expanded(
                child: RadioListTile<AttendanceMode>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Session',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                  subtitle: Text(
                    'Specific class',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  value: AttendanceMode.session,
                  groupValue: _attendanceMode,
                  onChanged: _schedules.isNotEmpty
                      ? (value) {
                          setState(() {
                            _attendanceMode = value!;
                          });
                        }
                      : null,
                  activeColor: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSelector() {
    // Filter schedules relevant for today's date
    final relevantSchedules = _schedules.where((schedule) {
      return schedule.isRelevantForDate(_attendanceDate) && schedule.isActive;
    }).toList();

    if (relevantSchedules.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700]),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'No scheduled sessions for ${DateFormat('EEEE, MMM d').format(_attendanceDate)}',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule),
              SizedBox(width: 2.w),
              Text(
                'Select Session:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              const Spacer(),
              if (_selectedScheduleIndex != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedScheduleIndex = null;
                    });
                  },
                  tooltip: 'Clear selection',
                ),
            ],
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: relevantSchedules.length,
            itemBuilder: (context, index) {
              final schedule = relevantSchedules[index];
              final isSelected = _selectedScheduleIndex == index;

              final startTimeFormatted =
                  DateFormat('h:mm a').format(schedule.startTime);
              final endTimeFormatted =
                  DateFormat('h:mm a').format(schedule.endTime);

              return Container(
                margin: EdgeInsets.symmetric(vertical: 1.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: schedule.isReplacement
                        ? AppColors.accentOrange.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                  color: schedule.isReplacement
                      ? AppColors.accentOrange.withOpacity(0.05)
                      : null,
                ),
                child: RadioListTile<int>(
                  title: Row(
                    children: [
                      if (schedule.isReplacement) ...[
                        Icon(
                          Icons.event_repeat,
                          size: 16,
                          color: AppColors.accentOrange,
                        ),
                        SizedBox(width: 1.w),
                      ],
                      Expanded(
                        child: Text(
                          schedule.displayTitle,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: schedule.isReplacement
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: schedule.isReplacement
                                ? AppColors.accentOrange
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${startTimeFormatted} - ${endTimeFormatted}',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      Text(
                        'Location: ${schedule.location}',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                      if (schedule.isReplacement &&
                          schedule.displaySubtitle.isNotEmpty)
                        Text(
                          schedule.displaySubtitle,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontStyle: FontStyle.italic,
                            color: AppColors.accentOrange,
                          ),
                        ),
                    ],
                  ),
                  value: index,
                  groupValue: _selectedScheduleIndex,
                  onChanged: (value) {
                    setState(() {
                      _selectedScheduleIndex = value;
                    });
                  },
                  activeColor: schedule.isReplacement
                      ? AppColors.accentOrange
                      : AppColors.primaryBlue,
                  selected: isSelected,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: 'Search by name or ID',
          hintStyle: TextStyle(fontSize: 14.sp),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          // QR Code Scanner Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _scanStudentQRCodes,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(
                'Scan QR Codes',
                style: TextStyle(fontSize: 14.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Bulk Actions:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 1.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  label: Text(
                    'All Present',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  avatar: Icon(Icons.check, color: AppColors.success),
                  backgroundColor: AppColors.success.withOpacity(0.1),
                  onPressed: () => _markAllStudents(AttendanceStatus.present),
                ),
                SizedBox(width: 2.w),
                ActionChip(
                  label: Text(
                    'All Absent',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  avatar: Icon(Icons.close, color: AppColors.error),
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  onPressed: () => _markAllStudents(AttendanceStatus.absent),
                ),
                SizedBox(width: 2.w),
                ActionChip(
                  label: Text(
                    'All Late',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  avatar: Icon(Icons.watch_later, color: AppColors.warning),
                  backgroundColor: AppColors.warning.withOpacity(0.1),
                  onPressed: () => _markAllStudents(AttendanceStatus.late),
                ),
                SizedBox(width: 2.w),
                ActionChip(
                  label: Text(
                    'All Excused',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  avatar:
                      Icon(Icons.medical_services, color: AppColors.accentTeal),
                  backgroundColor: AppColors.accentTeal.withOpacity(0.1),
                  onPressed: () => _markAllStudents(AttendanceStatus.excused),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildStudentsList(AttendanceState state) {
    if (state is AttendanceLoading &&
        _studentAttendances.isEmpty &&
        _filteredStudents.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(8.h),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading student data...'),
            ],
          ),
        ),
      );
    }

    List<Map<String, dynamic>> studentsToShow = [];

    if (state is EnrolledStudentsLoaded) {
      studentsToShow =
          _filteredStudents.isEmpty ? state.students : _filteredStudents;
    } else if (_filteredStudents.isNotEmpty) {
      studentsToShow = _filteredStudents;
    }

    if (studentsToShow.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(8.h),
        child: Center(
          child: Text(
            'No students enrolled in this course',
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: studentsToShow.length,
        itemBuilder: (context, index) {
          final student = studentsToShow[index];
          final studentId = student['studentId'] as String;
          final attendance =
              _studentAttendances[studentId] ?? AttendanceStatus.absent;
          final isSelected = _selectedStudents.contains(studentId);
          final hasAttendanceSet = _studentAttendances.containsKey(studentId);

          return _buildStudentCard(
              student, attendance, hasAttendanceSet, _batchEditMode,
              isSelected: isSelected);
        },
      ),
    );
  }

  Widget _buildStudentCard(
    Map<String, dynamic> student,
    AttendanceStatus attendance,
    bool hasAttendanceSet,
    bool isBatchMode, {
    bool isSelected = false,
  }) {
    final studentId = student['studentId'] as String;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      color: hasAttendanceSet
          ? _getAttendanceStatusColor(attendance).withOpacity(0.1)
          : null,
      child: isBatchMode
          ? ListTile(
              leading: Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedStudents.add(studentId);
                    } else {
                      _selectedStudents.remove(studentId);
                    }
                  });
                },
              ),
              title: Text(
                student['name'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              subtitle: Text(
                studentId,
                style: TextStyle(fontSize: 12.sp),
              ),
              trailing: _buildAttendanceStatusChip(attendance),
            )
          : ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: hasAttendanceSet
                    ? _getAttendanceStatusColor(attendance).withOpacity(0.7)
                    : AppColors.textLight,
                child: Text(
                  student['name'].toString().isNotEmpty
                      ? student['name'].toString()[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              title: Text(
                student['name'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              subtitle: Text(
                studentId,
                style: TextStyle(fontSize: 12.sp),
              ),
              trailing: _buildAttendanceStatusChip(attendance),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance Status:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      _buildAttendanceOptions(studentId),
                      SizedBox(height: 2.h),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Remarks (optional)',
                          labelStyle: TextStyle(fontSize: 13.sp),
                          hintText: 'Add any additional notes here...',
                          hintStyle: TextStyle(fontSize: 13.sp),
                          border: const OutlineInputBorder(),
                        ),
                        style: TextStyle(fontSize: 13.sp),
                        initialValue: _studentRemarks[studentId] ?? '',
                        onChanged: (value) {
                          setState(() {
                            _studentRemarks[studentId] = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBatchActionsPanel() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_selectedStudents.length} students selected',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBatchActionButton(
                'Present',
                Icons.check_circle,
                AppColors.success,
                () => _applyBatchStatus(AttendanceStatus.present),
              ),
              _buildBatchActionButton(
                'Absent',
                Icons.cancel,
                AppColors.error,
                () => _applyBatchStatus(AttendanceStatus.absent),
              ),
              _buildBatchActionButton(
                'Late',
                Icons.watch_later,
                AppColors.warning,
                () => _applyBatchStatus(AttendanceStatus.late),
              ),
              _buildBatchActionButton(
                'Excused',
                Icons.medical_services,
                AppColors.accentTeal,
                () => _applyBatchStatus(AttendanceStatus.excused),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    String buttonText;
    if (_studentAttendances.isEmpty) {
      buttonText = 'No Students to Record';
    } else if (_hasExistingRecords) {
      buttonText = 'Update Attendance (${_studentAttendances.length} students)';
    } else {
      buttonText = 'Save Attendance (${_studentAttendances.length} students)';
    }

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting || _studentAttendances.isEmpty
              ? null
              : _submitAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _hasExistingRecords ? Colors.orange : AppColors.primaryBlue,
            padding: EdgeInsets.symmetric(vertical: 2.h),
          ),
          child: Text(
            buttonText,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getAttendanceStatusColor(AttendanceStatus status) {
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

  Widget _buildAttendanceStatusChip(AttendanceStatus status) {
    Color chipColor;
    String label;

    switch (status) {
      case AttendanceStatus.present:
        chipColor = AppColors.success;
        label = 'Present';
        break;
      case AttendanceStatus.absent:
        chipColor = AppColors.error;
        label = 'Absent';
        break;
      case AttendanceStatus.late:
        chipColor = AppColors.warning;
        label = 'Late';
        break;
      case AttendanceStatus.excused:
        chipColor = AppColors.accentTeal;
        label = 'Excused';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _buildAttendanceOptions(String studentId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAttendanceOption(
          studentId,
          AttendanceStatus.present,
          'Present',
          AppColors.success,
        ),
        _buildAttendanceOption(
          studentId,
          AttendanceStatus.absent,
          'Absent',
          AppColors.error,
        ),
        _buildAttendanceOption(
          studentId,
          AttendanceStatus.late,
          'Late',
          AppColors.warning,
        ),
        _buildAttendanceOption(
          studentId,
          AttendanceStatus.excused,
          'Excused',
          AppColors.accentTeal,
        ),
      ],
    );
  }

  Widget _buildAttendanceOption(
    String studentId,
    AttendanceStatus status,
    String label,
    Color color,
  ) {
    final isSelected = _studentAttendances[studentId] == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _studentAttendances[studentId] = status;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildBatchActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white, size: 16),
      label: Text(
        label,
        style: TextStyle(fontSize: 12.sp),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      ),
    );
  }
}
