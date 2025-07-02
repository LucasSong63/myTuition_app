import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import '../../data/models/attendance_model.dart';
import '../../domain/entities/attendance.dart';
import '../bloc/student_attendance_history_bloc.dart';
import '../bloc/student_attendance_history_event.dart';
import '../bloc/student_attendance_history_state.dart';

class StudentAttendanceHistoryPage extends StatefulWidget {
  const StudentAttendanceHistoryPage({Key? key}) : super(key: key);

  @override
  State<StudentAttendanceHistoryPage> createState() =>
      _StudentAttendanceHistoryPageState();
}

class _StudentAttendanceHistoryPageState
    extends State<StudentAttendanceHistoryPage> {
  String _studentId = '';
  String? _selectedStatus;
  String? _selectedCourse;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _getStudentIdAndLoadData();
  }

  void _getStudentIdAndLoadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _studentId = authState.user.studentId ?? '';
      if (_studentId.isNotEmpty) {
        context.read<StudentAttendanceHistoryBloc>().add(
              LoadStudentAttendanceHistoryEvent(studentId: _studentId),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            title: Text(
              'Attendance History',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
          ),
          body: BlocBuilder<StudentAttendanceHistoryBloc, StudentAttendanceHistoryState>(
            builder: (context, state) {
              if (state is StudentAttendanceHistoryLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is StudentAttendanceHistoryError) {
                return _buildErrorState(state.message);
              }

              if (state is StudentAttendanceHistoryLoaded) {
                return _buildLoadedState(state);
              }

              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 50.sp,
              color: AppColors.error,
            ),
            SizedBox(height: 2.h),
            Text(
              'Error loading attendance',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textMedium,
              ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: _getStudentIdAndLoadData,
              child: Text(
                'Retry',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(StudentAttendanceHistoryLoaded state) {
    final courses = _extractUniqueCourses(state.allAttendance);

    return CustomScrollView(
      slivers: [
        // Statistics Cards
        SliverToBoxAdapter(
          child: _buildStatisticsSection(state.statistics),
        ),

        // Filter Section
        SliverToBoxAdapter(
          child: _buildFilterSection(courses),
        ),

        // Attendance List Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(2.w, 2.h, 2.w, 1.h),
            child: Row(
              children: [
                Icon(Icons.history, color: AppColors.primaryBlue, size: 20.sp),
                SizedBox(width: 1.w),
                Text(
                  'Attendance Records',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.filteredAttendance.length} records',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Attendance List
        if (state.filteredAttendance.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildAttendanceCard(state.filteredAttendance[index]),
                childCount: state.filteredAttendance.length,
              ),
            ),
          ),

        // Bottom padding
        SliverToBoxAdapter(
          child: SizedBox(height: 3.h),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(Map<String, dynamic> statistics) {
    return Container(
      margin: EdgeInsets.all(2.w),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Attendance',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Attendance Rate',
                  value: '${statistics['attendanceRate'].toStringAsFixed(1)}%',
                  color: AppColors.success,
                  icon: Icons.pie_chart,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Classes',
                  value: statistics['totalClasses'].toString(),
                  color: AppColors.primaryBlue,
                  icon: Icons.calendar_today,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildSmallStatCard(
                  title: 'Present',
                  value: statistics['presentCount'].toString(),
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: _buildSmallStatCard(
                  title: 'Absent',
                  value: statistics['absentCount'].toString(),
                  color: AppColors.error,
                ),
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: _buildSmallStatCard(
                  title: 'Late',
                  value: statistics['lateCount'].toString(),
                  color: AppColors.warning,
                ),
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: _buildSmallStatCard(
                  title: 'Excused',
                  value: statistics['excusedCount'].toString(),
                  color: AppColors.accentTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(1.5.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 9.sp,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(Map<String, String> courses) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status Filter
                _buildFilterChip(
                  label: _selectedStatus ?? 'All Status',
                  icon: Icons.check_circle_outline,
                  onTap: () => _showStatusFilterDialog(),
                  isActive: _selectedStatus != null,
                ),
                SizedBox(width: 1.w),
                
                // Course Filter
                _buildFilterChip(
                  label: _selectedCourse != null 
                      ? courses[_selectedCourse] ?? 'Unknown Course'
                      : 'All Courses',
                  icon: Icons.book,
                  onTap: () => _showCourseFilterDialog(courses),
                  isActive: _selectedCourse != null,
                ),
                SizedBox(width: 1.w),
                
                // Date Range Filter
                _buildFilterChip(
                  label: _selectedDateRange != null
                      ? '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                      : 'All Time',
                  icon: Icons.date_range,
                  onTap: () => _showDateRangeFilterDialog(),
                  isActive: _selectedDateRange != null,
                ),
                
                // Clear Filters
                if (_selectedStatus != null || _selectedCourse != null || _selectedDateRange != null)
                  Container(
                    margin: EdgeInsets.only(left: 1.w),
                    child: IconButton(
                      icon: Icon(Icons.clear, size: 18.sp),
                      onPressed: _clearFilters,
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primaryBlue : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: isActive ? Colors.white : AppColors.textMedium,
            ),
            SizedBox(width: 1.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: isActive ? Colors.white : AppColors.textDark,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel attendance) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Row(
          children: [
            // Status Icon
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: _getStatusColor(attendance.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getStatusIcon(attendance.status),
                color: _getStatusColor(attendance.status),
                size: 20.sp,
              ),
            ),
            SizedBox(width: 2.w),
            
            // Attendance Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attendance.courseId.replaceAll('-', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 11.sp,
                        color: AppColors.textMedium,
                      ),
                      SizedBox(width: 0.5.w),
                      Text(
                        DateFormat('EEEE, d MMM yyyy').format(attendance.date),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                  if (attendance.scheduleTimeDisplay != 'Session Time') ...[
                    SizedBox(height: 0.3.h),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 11.sp,
                          color: AppColors.textMedium,
                        ),
                        SizedBox(width: 0.5.w),
                        Text(
                          attendance.scheduleTimeDisplay,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (attendance.scheduleLocation != null) ...[
                    SizedBox(height: 0.3.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 11.sp,
                          color: AppColors.textMedium,
                        ),
                        SizedBox(width: 0.5.w),
                        Flexible(
                          child: Text(
                            attendance.scheduleLocation!,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textMedium,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (attendance.remarks != null && attendance.remarks!.isNotEmpty) ...[
                    SizedBox(height: 0.5.h),
                    Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.note,
                            size: 11.sp,
                            color: AppColors.textMedium,
                          ),
                          SizedBox(width: 0.5.w),
                          Expanded(
                            child: Text(
                              attendance.remarks!,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.textMedium,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Status Badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 2.w,
                vertical: 0.5.h,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(attendance.status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(attendance.status),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 50.sp,
            color: AppColors.textLight,
          ),
          SizedBox(height: 2.h),
          Text(
            'No attendance records found',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textMedium,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _extractUniqueCourses(List<AttendanceModel> attendance) {
    final courses = <String, String>{};
    for (var record in attendance) {
      if (!courses.containsKey(record.courseId)) {
        // Extract course name from courseId (e.g., "bahasa-malaysia-grade1" -> "Bahasa Malaysia Grade 1")
        final parts = record.courseId.split('-');
        if (parts.length >= 3) {
          final subject = parts.sublist(0, parts.length - 1).join(' ');
          final grade = parts.last.replaceAll('grade', 'Grade ');
          courses[record.courseId] = '${_capitalizeWords(subject)} $grade';
        } else {
          courses[record.courseId] = record.courseId;
        }
      }
    }
    return courses;
  }

  String _capitalizeWords(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _showStatusFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filter by Status',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('All Status', null),
            _buildStatusOption('Present', 'present'),
            _buildStatusOption('Absent', 'absent'),
            _buildStatusOption('Late', 'late'),
            _buildStatusOption('Excused', 'excused'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(String label, String? value) {
    return ListTile(
      title: Text(label, style: TextStyle(fontSize: 13.sp)),
      leading: Radio<String?>(
        value: value,
        groupValue: _selectedStatus,
        onChanged: (newValue) {
          setState(() {
            _selectedStatus = newValue;
          });
          context.read<StudentAttendanceHistoryBloc>().add(
                FilterAttendanceByStatusEvent(statusFilter: newValue),
              );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showCourseFilterDialog(Map<String, String> courses) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filter by Course',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCourseOption('All Courses', null),
              ...courses.entries.map((entry) => 
                _buildCourseOption(entry.value, entry.key)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseOption(String label, String? value) {
    return ListTile(
      title: Text(label, style: TextStyle(fontSize: 13.sp)),
      leading: Radio<String?>(
        value: value,
        groupValue: _selectedCourse,
        onChanged: (newValue) {
          setState(() {
            _selectedCourse = newValue;
          });
          context.read<StudentAttendanceHistoryBloc>().add(
                FilterAttendanceByCourseEvent(courseFilter: newValue),
              );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDateRangeFilterDialog() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      context.read<StudentAttendanceHistoryBloc>().add(
            FilterAttendanceByDateRangeEvent(
              startDate: picked.start,
              endDate: picked.end,
            ),
          );
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedCourse = null;
      _selectedDateRange = null;
    });
    
    context.read<StudentAttendanceHistoryBloc>()
      ..add(const FilterAttendanceByStatusEvent(statusFilter: null))
      ..add(const FilterAttendanceByCourseEvent(courseFilter: null))
      ..add(const FilterAttendanceByDateRangeEvent(startDate: null, endDate: null));
  }

  Color _getStatusColor(AttendanceStatus status) {
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

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.excused:
        return Icons.info;
    }
  }

  String _getStatusText(AttendanceStatus status) {
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
}
