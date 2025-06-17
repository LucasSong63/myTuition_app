// lib/features/attendance/presentation/pages/manage_attendance_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/attendance/presentation/pages/take_attendance_page.dart';
import 'package:mytuition/core/utils/navigation_utils.dart';

import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../../domain/entities/attendance.dart';

// Import widgets
import '../widgets/manage/attendance_app_bar.dart';
import '../widgets/manage/summary_tab_content.dart';
import '../widgets/manage/history_tab_content.dart';
import '../widgets/manage/take_attendance_fab.dart';

class ManageAttendancePage extends StatefulWidget {
  final String courseId;
  final String courseName;

  const ManageAttendancePage({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  State<ManageAttendancePage> createState() => _ManageAttendancePageState();
}

class _ManageAttendancePageState extends State<ManageAttendancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _past7DaysLoading = false;
  Map<String, dynamic>? _stats;

  // For past 7 days attendance (OPTIMIZED)
  Map<String, List<Attendance>> _past7DaysAttendance = {};
  Map<String, List<Attendance>> _olderAttendance = {};
  List<Map<String, dynamic>> _students = [];

  // Date range filter
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    // Load attendance statistics and students
    context.read<AttendanceBloc>().add(
          LoadCourseAttendanceStatsEvent(courseId: widget.courseId),
        );
    context.read<AttendanceBloc>().add(
          LoadEnrolledStudentsEvent(courseId: widget.courseId),
        );

    // OPTIMIZED: Load past 7 days with single query
    _loadPast7DaysAttendance();
  }

  // PHASE 3.1: OPTIMIZED - Single query instead of 7 separate queries
  void _loadPast7DaysAttendance() {
    setState(() {
      _past7DaysLoading = true;
    });

    // Single event call instead of loop with 7 separate calls
    context.read<AttendanceBloc>().add(
          LoadPast7DaysAttendanceEvent(courseId: widget.courseId),
        );
  }

  void _loadAttendanceForDateRange(DateTime start, DateTime end) {
    setState(() {
      _past7DaysLoading = true;
      _past7DaysAttendance.clear();
      _olderAttendance.clear();
    });

    // For custom date ranges, still need to load individually
    // In a real implementation, you might extend the repository
    // to support custom date ranges efficiently
    final days = end.difference(start).inDays;

    for (int i = 0; i <= days; i++) {
      final date = start.add(Duration(days: i));
      context.read<AttendanceBloc>().add(
            LoadAttendanceByDateEvent(
              courseId: widget.courseId,
              date: date,
            ),
          );
    }
  }

  void _showDateRangeFilter() async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _endDate ?? DateTime.now(),
    );

    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDateRange != null) {
      setState(() {
        _startDate = pickedDateRange.start;
        _endDate = pickedDateRange.end;
      });

      // Load attendance for custom date range
      _loadAttendanceForDateRange(_startDate!, _endDate!);

      // Reload stats with date range
      context.read<AttendanceBloc>().add(
            LoadCourseAttendanceStatsWithDateRangeEvent(
              courseId: widget.courseId,
              startDate: _startDate!,
              endDate: _endDate!,
            ),
          );
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });

    // Reload default past 7 days and stats
    _loadPast7DaysAttendance();
    context.read<AttendanceBloc>().add(
          LoadCourseAttendanceStatsEvent(courseId: widget.courseId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AttendanceAppBar(
        courseName: widget.courseName,
        tabController: _tabController,
        onDateRangeFilter: _showDateRangeFilter,
        onClearFilter: _clearDateFilter,
        hasActiveFilter: _startDate != null || _endDate != null,
      ),
      body: BlocListener<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is CourseAttendanceStatsLoaded) {
            setState(() {
              _stats = state.stats;
              _isLoading = false;
            });
          }

          if (state is EnrolledStudentsLoaded) {
            setState(() {
              _students = state.students;
            });
          }

          // PHASE 3.1: NEW - Handle optimized past 7 days loading
          if (state is Past7DaysAttendanceLoaded) {
            setState(() {
              // FIXED: More inclusive comparison for past 7 days
              final now = DateTime.now();
              final today = DateTime(
                  now.year, now.month, now.day); // Normalize to date only
              final sevenDaysAgo = today.subtract(
                  const Duration(days: 6)); // Include today + 6 days back

              _past7DaysAttendance.clear();
              _olderAttendance.clear();

              state.attendanceMap.forEach((dateKey, records) {
                final date = DateTime.parse(dateKey);
                final dateOnly = DateTime(date.year, date.month, date.day);

                if (dateOnly.isAfter(sevenDaysAgo) ||
                    dateOnly.isAtSameMomentAs(sevenDaysAgo)) {
                  _past7DaysAttendance[dateKey] = records;
                } else {
                  _olderAttendance[dateKey] = records;
                }
              });

              _past7DaysLoading = false;
            });
          }

          // Handle individual date loading (for custom date ranges)
          if (state is AttendanceByDateLoaded) {
            setState(() {
              final dateKey = DateFormat('yyyy-MM-dd').format(state.date);
              if (state.attendanceRecords.isNotEmpty) {
                _past7DaysAttendance[dateKey] = state.attendanceRecords;
              }
              _past7DaysLoading = false;
            });
          }

          if (state is AttendanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
            setState(() {
              _isLoading = false;
              _past7DaysLoading = false;
            });
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            SummaryTabContent(
              isLoading: _isLoading,
              stats: _stats,
              startDate: _startDate,
              endDate: _endDate,
              students: _students,
            ),
            HistoryTabContent(
              isLoading: _past7DaysLoading,
              startDate: _startDate,
              endDate: _endDate,
              past7DaysAttendance: _past7DaysAttendance,
              olderAttendance: _olderAttendance,
              onDateRangeChanged: _loadAttendanceForDateRange,
              onRefresh: _loadInitialData,
              courseId: widget.courseId,
              courseName: widget.courseName,
            ),
          ],
        ),
      ),
      floatingActionButton: TakeAttendanceFAB(
        courseId: widget.courseId,
        courseName: widget.courseName,
        onReturn: _loadInitialData,
      ),
    );
  }
}
