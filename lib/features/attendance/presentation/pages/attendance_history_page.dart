import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/attendance/presentation/pages/student_attendance_details_page.dart';
import 'package:mytuition/features/attendance/presentation/pages/take_attendance_page.dart';
import '../../domain/entities/attendance.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load attendance statistics and student data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Load both stats and students when page is initialized
        context.read<AttendanceBloc>().add(
              LoadCourseAttendanceStatsEvent(courseId: widget.courseId),
            );
        context.read<AttendanceBloc>().add(
              LoadEnrolledStudentsEvent(courseId: widget.courseId),
            );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  Tab(text: 'Students'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is CourseAttendanceStatsLoaded) {
            setState(() {
              _stats = state.stats;
              _isLoading = false;
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

              // Students tab
              _buildStudentsTab(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Create a new AttendanceBloc instance from GetIt
          final GetIt getIt = GetIt.instance;
          final attendanceBloc = getIt<AttendanceBloc>();

          // Initialize the new bloc with the relevant data
          attendanceBloc.add(
            LoadEnrolledStudentsEvent(courseId: widget.courseId),
          );
          attendanceBloc.add(
            LoadAttendanceByDateEvent(
              courseId: widget.courseId,
              date: DateTime.now(),
            ),
          );

          // Navigate with the new bloc
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) => BlocProvider<AttendanceBloc>(
                create: (context) => attendanceBloc,
                child: TakeAttendancePage(
                  courseId: widget.courseId,
                  courseName: widget.courseName,
                ),
              ),
            ),
          )
              .then((_) {
            // Refresh stats when returning from taking attendance
            if (mounted) {
              context.read<AttendanceBloc>().add(
                    LoadCourseAttendanceStatsEvent(courseId: widget.courseId),
                  );
            }
          });
        },
        label: const Text('Take Attendance'),
        icon: const Icon(Icons.edit),
      ),
    );
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // Status distribution
          const Text(
            'Attendance Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildStatusBar(
                    'Present',
                    statusCounts['present'] ?? 0,
                    totalStudents * totalDays,
                    AppColors.success,
                  ),
                  const SizedBox(height: 16),
                  _buildStatusBar(
                    'Late',
                    statusCounts['late'] ?? 0,
                    totalStudents * totalDays,
                    AppColors.warning,
                  ),
                  const SizedBox(height: 16),
                  _buildStatusBar(
                    'Excused',
                    statusCounts['excused'] ?? 0,
                    totalStudents * totalDays,
                    AppColors.accentTeal,
                  ),
                  const SizedBox(height: 16),
                  _buildStatusBar(
                    'Absent',
                    statusCounts['absent'] ?? 0,
                    totalStudents * totalDays,
                    AppColors.error,
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

  Widget _buildStatusBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}% ($count)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildStudentsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is EnrolledStudentsLoaded) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      builder: (context, state) {
        if (state is EnrolledStudentsLoaded) {
          if (state.students.isEmpty) {
            return const Center(
              child: Text('No students enrolled in this course'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AttendanceBloc>().add(
                    LoadEnrolledStudentsEvent(courseId: widget.courseId),
                  );
              return Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: state.students.length,
              itemBuilder: (context, index) {
                final student = state.students[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _getSubjectColor(widget.courseName).withOpacity(0.7),
                      child: Text(
                        student['name'].toString().isNotEmpty
                            ? student['name'].toString()[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      student['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(student['studentId'] as String),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // The critical fix: Create a NEW instance of the AttendanceBloc and pass it to the new page
                      final GetIt getIt = GetIt.instance;

                      // Create a completely fresh AttendanceBloc
                      final attendanceBloc = getIt<AttendanceBloc>();

                      // Load the student attendance data with this new bloc
                      attendanceBloc.add(LoadStudentAttendanceEvent(
                        courseId: widget.courseId,
                        studentId: student['studentId'] as String,
                      ));

                      // Now navigate with the new bloc
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider<AttendanceBloc>(
                            create: (context) => attendanceBloc,
                            child: StudentAttendanceDetailsPage(
                              student: student,
                              courseName: widget.courseName,
                              courseId: widget.courseId, // Pass the courseId
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        }

        // Load students if they haven't been loaded yet
        if (!(state is EnrolledStudentsLoaded)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AttendanceBloc>().add(
                  LoadEnrolledStudentsEvent(courseId: widget.courseId),
                );
          });
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No student data available'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<AttendanceBloc>().add(
                        LoadEnrolledStudentsEvent(courseId: widget.courseId),
                      );
                },
                child: const Text('Load Students'),
              ),
            ],
          ),
        );
      },
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
}
