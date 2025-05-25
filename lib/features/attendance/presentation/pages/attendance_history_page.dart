import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/core/utils/navigation_utils.dart';

import 'package:intl/intl.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/attendance/presentation/pages/student_attendance_details_page.dart';
import 'package:mytuition/features/attendance/presentation/pages/take_attendance_page.dart';

import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../widgets/attendance_charts.dart';
import '../../domain/entities/attendance.dart';

class AttendanceHistoryPage extends StatefulWidget {
  final String courseId;
  final String courseName;

  const AttendanceHistoryPage({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  // For attendance history
  List<Attendance> _attendanceRecords = [];
  Map<String, List<Attendance>> _groupedAttendance = {};
  List<Map<String, dynamic>> _students = [];

  // Date range filter
  DateTime? _startDate;
  DateTime? _endDate;

  // For trends data
  List<Map<String, dynamic>> _weeklyTrends = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load attendance statistics, students, and attendance history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AttendanceBloc>().add(
              LoadCourseAttendanceStatsEvent(courseId: widget.courseId),
            );
        context.read<AttendanceBloc>().add(
              LoadEnrolledStudentsEvent(courseId: widget.courseId),
            );
        _loadAttendanceHistory();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAttendanceHistory() {
    // Load all attendance records by default (All Time)
    // In a real implementation, you'd add a new event/usecase for loading all attendance history
    // For now, we'll load a reasonable range (last 365 days) to represent "All Time"
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 365));

    _loadAttendanceForDateRange(startDate, endDate);
  }

  void _loadAttendanceForDateRange(DateTime start, DateTime end) {
    // This is a simplified approach. Ideally, you'd create a new event
    // LoadAttendanceHistoryEvent that loads all records in a date range

    // For now, we'll load attendance for each day in the range
    // This is not optimal for large date ranges, but works for demonstration
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

      // Reload attendance history with new date range
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

    // Reload default attendance history (All Time) and stats
    _loadAttendanceHistory();
    context.read<AttendanceBloc>().add(
          LoadCourseAttendanceStatsEvent(courseId: widget.courseId),
        );
  }

  void _groupAttendanceByDate() {
    _groupedAttendance.clear();

    for (var record in _attendanceRecords) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.date);
      _groupedAttendance[dateKey] = _groupedAttendance[dateKey] ?? [];
      _groupedAttendance[dateKey]!.add(record);
    }

    // Sort dates in descending order (most recent first)
    final sortedKeys = _groupedAttendance.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final sortedGroupedAttendance = <String, List<Attendance>>{};
    for (final key in sortedKeys) {
      sortedGroupedAttendance[key] = _groupedAttendance[key]!;
    }

    _groupedAttendance = sortedGroupedAttendance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.courseName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                tabs: const [
                  Tab(text: 'Summary'),
                  Tab(text: 'History'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filter by date',
            onPressed: _showDateRangeFilter,
          ),
        ],
      ),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is CourseAttendanceStatsLoaded) {
            setState(() {
              _stats = state.stats;
              _isLoading = false;

              // Generate weekly trends from stats
              _generateWeeklyTrends();
            });
          }

          if (state is AttendanceWeeklyTrendsLoaded) {
            setState(() {
              _weeklyTrends = state.weeklyData;
            });
          }

          if (state is EnrolledStudentsLoaded) {
            setState(() {
              _students = state.students;
            });
          }

          if (state is AttendanceByDateLoaded) {
            // Add the loaded attendance records to our collection
            setState(() {
              // Remove any existing records for this date to avoid duplicates
              final dateKey = DateFormat('yyyy-MM-dd').format(state.date);
              _attendanceRecords.removeWhere((record) =>
                  DateFormat('yyyy-MM-dd').format(record.date) == dateKey);

              // Add the new records
              _attendanceRecords.addAll(state.attendanceRecords);

              // Regroup the attendance by date
              _groupAttendanceByDate();
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
            });
          }
        },
        builder: (context, state) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Summary tab
              _buildSummaryTab(),

              // History tab (previously Students tab)
              _buildHistoryTab(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Use the BlocNavigator utility to navigate with a new BLoC
          BlocNavigator.navigateWithNewBloc<AttendanceBloc, void>(
            context: context,
            pageBuilder: (context, bloc) => TakeAttendancePage(
              courseId: widget.courseId,
              courseName: widget.courseName,
            ),
            initEvents: [
              (bloc) => bloc
                  .add(LoadEnrolledStudentsEvent(courseId: widget.courseId)),
              (bloc) => bloc.add(LoadAttendanceByDateEvent(
                    courseId: widget.courseId,
                    date: DateTime.now(),
                  )),
              (bloc) =>
                  bloc.add(LoadCourseSchedulesEvent(courseId: widget.courseId)),
            ],
            onReturn: (_) {
              // Refresh data when returning from taking attendance
              if (mounted) {
                context.read<AttendanceBloc>().add(
                      LoadCourseAttendanceStatsEvent(courseId: widget.courseId),
                    );
                _loadAttendanceHistory();
              }
            },
          );
        },
        label: const Text('Take Attendance'),
        icon: const Icon(Icons.edit),
      ),
    );
  }

  void _generateWeeklyTrends() {
    // This is a placeholder. In a real implementation, you would
    // request this data from the backend via the BLoC
    _weeklyTrends = [
      {'week': 'Week 1', 'attendanceRate': 0.85},
      {'week': 'Week 2', 'attendanceRate': 0.90},
      {'week': 'Week 3', 'attendanceRate': 0.82},
      {'week': 'Week 4', 'attendanceRate': 0.88},
    ];
  }

  Widget _buildSummaryTab() {
    if (_stats == null) {
      return const Center(
        child: Text('No attendance data available'),
      );
    }

    final totalStudents = _stats!['totalStudents'] as int;
    final totalDays = _stats!['totalDays'] as int;
    final statusCounts = _stats!['statusCounts'] as Map<String, int>;
    final attendanceRate = _stats!['attendanceRate'] as double;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AttendanceBloc>().add(
              LoadCourseAttendanceStatsEvent(courseId: widget.courseId),
            );
        return Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date filter indicator
            if (_startDate != null && _endDate != null)
              Card(
                color: AppColors.primaryBlueLight.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Filtered: ${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _clearDateFilter,
                        tooltip: 'Clear filter',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    ],
                  ),
                ),
              ),

            // Course info card at the top
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _getSubjectIcon(widget.courseName),
                      size: 36,
                      color: _getSubjectColor(widget.courseName),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.courseName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Overview card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOverviewItem(
                      'Students',
                      '$totalStudents',
                      Icons.people,
                      AppColors.primaryBlue,
                    ),
                    const Divider(),
                    _buildOverviewItem(
                      'Class Days',
                      '$totalDays',
                      Icons.calendar_today,
                      AppColors.accentTeal,
                    ),
                    const Divider(),
                    _buildOverviewItem(
                      'Attendance Rate',
                      '${(attendanceRate * 100).toStringAsFixed(1)}%',
                      Icons.check_circle,
                      AppColors.success,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Attendance pie chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance Distribution',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AttendancePieChart(
                      statusCounts: statusCounts,
                      totalAttendances: totalStudents * totalDays,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Trends chart
            if (_weeklyTrends.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance Trends',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AttendanceTrendChart(
                        weeklyData: _weeklyTrends,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Actions
            Card(
              child: ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export Attendance Report'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Implement export functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export functionality coming soon!'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(
      String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadAttendanceHistory();
        return Future.delayed(const Duration(milliseconds: 500));
      },
      child: Column(
        children: [
          // Date range info and quick filters
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _startDate != null && _endDate != null
                          ? '${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}'
                          : 'All Time',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_attendanceRecords.isNotEmpty)
                      Text(
                        '${_groupedAttendance.length} days',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quick filter buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickFilterChip('Last 7 days', () {
                        final end = DateTime.now();
                        final start = end.subtract(const Duration(days: 7));
                        setState(() {
                          _startDate = start;
                          _endDate = end;
                        });
                        _loadAttendanceForDateRange(start, end);
                      }),
                      const SizedBox(width: 8),
                      _buildQuickFilterChip('Last 30 days', () {
                        final end = DateTime.now();
                        final start = end.subtract(const Duration(days: 30));
                        setState(() {
                          _startDate = start;
                          _endDate = end;
                        });
                        _loadAttendanceForDateRange(start, end);
                      }),
                      const SizedBox(width: 8),
                      _buildQuickFilterChip('This month', () {
                        final now = DateTime.now();
                        final start = DateTime(now.year, now.month, 1);
                        final end = DateTime(now.year, now.month + 1, 0);
                        setState(() {
                          _startDate = start;
                          _endDate = end;
                        });
                        _loadAttendanceForDateRange(start, end);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Attendance history list
          Expanded(
            child: _groupedAttendance.isEmpty
                ? Center(
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
                        Text(
                          _startDate != null && _endDate != null
                              ? 'No records in the selected date range'
                              : 'No attendance records found for this course',
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _groupedAttendance.length,
                    itemBuilder: (context, index) {
                      final dateKey = _groupedAttendance.keys.elementAt(index);
                      final records = _groupedAttendance[dateKey]!;
                      final date = DateTime.parse(dateKey);

                      return _buildAttendanceDateCard(date, records);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onPressed) {
    // Determine if this filter is currently active
    bool isActive = false;
    if (label == 'All Time') {
      isActive = _startDate == null && _endDate == null;
    } else if (label == 'Last 7 days' &&
        _startDate != null &&
        _endDate != null) {
      final daysDiff = _endDate!.difference(_startDate!).inDays;
      isActive = daysDiff == 7;
    } else if (label == 'Last 30 days' &&
        _startDate != null &&
        _endDate != null) {
      final daysDiff = _endDate!.difference(_startDate!).inDays;
      isActive = daysDiff == 30;
    } else if (label == 'This month' &&
        _startDate != null &&
        _endDate != null) {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      isActive = _startDate!.year == monthStart.year &&
          _startDate!.month == monthStart.month &&
          _startDate!.day == monthStart.day &&
          _endDate!.year == monthEnd.year &&
          _endDate!.month == monthEnd.month &&
          _endDate!.day == monthEnd.day;
    }

    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isActive ? Colors.white : AppColors.primaryBlue,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onPressed: onPressed,
      backgroundColor: isActive
          ? AppColors.primaryBlue
          : AppColors.primaryBlue.withOpacity(0.1),
      side: BorderSide(
        color: isActive
            ? AppColors.primaryBlue
            : AppColors.primaryBlue.withOpacity(0.3),
      ),
    );
  }

  Widget _buildAttendanceDateCard(DateTime date, List<Attendance> records) {
    // Calculate statistics for this date
    final statusCounts = <AttendanceStatus, int>{};
    for (var record in records) {
      statusCounts[record.status] = (statusCounts[record.status] ?? 0) + 1;
    }

    final totalRecords = records.length;
    final presentCount = (statusCounts[AttendanceStatus.present] ?? 0) +
        (statusCounts[AttendanceStatus.late] ?? 0);
    final attendanceRate = totalRecords > 0 ? presentCount / totalRecords : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getAttendanceRateColor(attendanceRate).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today,
            color: _getAttendanceRateColor(attendanceRate),
          ),
        ),
        title: Text(
          DateFormat('EEEE, MMMM d, yyyy').format(date),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '$totalRecords students • ${(attendanceRate * 100).toStringAsFixed(0)}% attendance rate',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusCountChip(
              statusCounts[AttendanceStatus.present] ?? 0,
              'P',
              AppColors.success,
            ),
            const SizedBox(width: 4),
            _buildStatusCountChip(
              statusCounts[AttendanceStatus.late] ?? 0,
              'L',
              AppColors.warning,
            ),
            const SizedBox(width: 4),
            _buildStatusCountChip(
              statusCounts[AttendanceStatus.absent] ?? 0,
              'A',
              AppColors.error,
            ),
            const SizedBox(width: 4),
            _buildStatusCountChip(
              statusCounts[AttendanceStatus.excused] ?? 0,
              'E',
              AppColors.accentTeal,
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: records.map((record) {
                final student = _students.firstWhere(
                  (s) => s['studentId'] == record.studentId,
                  orElse: () => {
                    'name': 'Unknown Student',
                    'studentId': record.studentId
                  },
                );

                return _buildStudentAttendanceRecord(record, student);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCountChip(int count, String label, Color color) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$count$label',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStudentAttendanceRecord(
      Attendance record, Map<String, dynamic> student) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: statusColor.withOpacity(0.2),
            child: Text(
              student['name'].toString().isNotEmpty
                  ? student['name'].toString()[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  record.studentId,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (record.remarks != null && record.remarks!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Note: ${record.remarks}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.person, size: 18),
            tooltip: 'View student details',
            onPressed: () {
              // Navigate to individual student attendance details
              BlocNavigator.navigateWithNewBloc<AttendanceBloc, void>(
                context: context,
                pageBuilder: (context, bloc) => StudentAttendanceDetailsPage(
                  student: student,
                  courseName: widget.courseName,
                  courseId: widget.courseId,
                ),
                initEvents: [
                  (bloc) => bloc.add(LoadStudentAttendanceEvent(
                        courseId: widget.courseId,
                        studentId: student['studentId'] as String,
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper methods for subject colors and icons
  Color _getSubjectColor(String subject) {
    subject = subject.toLowerCase();
    if (subject.contains('math')) return AppColors.mathSubject;
    if (subject.contains('science')) return AppColors.scienceSubject;
    if (subject.contains('english')) return AppColors.englishSubject;
    if (subject.contains('bahasa')) return AppColors.bahasaSubject;
    if (subject.contains('chinese')) return AppColors.chineseSubject;
    return AppColors.primaryBlue;
  }

  IconData _getSubjectIcon(String subject) {
    subject = subject.toLowerCase();
    if (subject.contains('math')) return Icons.calculate;
    if (subject.contains('science')) return Icons.science;
    if (subject.contains('english')) return Icons.menu_book;
    if (subject.contains('bahasa')) return Icons.language;
    if (subject.contains('chinese')) return Icons.translate;
    return Icons.school;
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
