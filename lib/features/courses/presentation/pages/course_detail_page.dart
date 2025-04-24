import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:mytuition/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:mytuition/features/attendance/presentation/pages/attendance_history_page.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_state.dart';
import 'package:mytuition/features/courses/presentation/widgets/capacity_edit_bottom_sheet.dart';
import 'package:mytuition/features/courses/presentation/widgets/capacity_indicator_widget.dart';
import 'package:mytuition/features/courses/presentation/widgets/schedule_dialog.dart';
import 'package:mytuition/features/tasks/domain/entities/task.dart';
import 'package:mytuition/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:mytuition/features/tasks/presentation/bloc/task_event.dart';
import 'package:mytuition/features/tasks/presentation/bloc/task_state.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/schedule.dart';
import '../bloc/course_bloc.dart';
import '../bloc/course_event.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseId;

  const CourseDetailPage({
    super.key,
    required this.courseId,
  });

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final GetIt getIt = GetIt.instance;

  @override
  Widget build(BuildContext context) {
    // Check if user is a tutor
    final authState = context.read<AuthBloc>().state;
    final isTutor = authState is Authenticated && authState.isTutor;

    return BlocConsumer<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state is CourseActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
        }

        if (state is CourseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        // First check for error state
        if (state is CourseError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Course Details'),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CourseBloc>().add(
                            LoadCourseDetailsEvent(courseId: widget.courseId),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Then check for loading state or if we need to refresh
        if (state is! CourseDetailsLoaded ||
            (state is CourseDetailsLoaded &&
                state.course.id != widget.courseId)) {
          context.read<CourseBloc>().add(
                LoadCourseDetailsEvent(courseId: widget.courseId),
              );

          return Scaffold(
            appBar: AppBar(
              title: const Text('Course Details'),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Now handle the course details state
        final course = state.course;

        return Scaffold(
          appBar: AppBar(
            title: Text(course.subject),
            backgroundColor: _getSubjectColor(course.subject),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero banner
                _buildHeroBanner(context, course),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course info card
                      _buildCourseInfoCard(context, course),

                      const SizedBox(height: 24),

                      // Tutor actions section (only for tutors)
                      if (isTutor) _buildTutorActionsSection(context, course),

                      if (isTutor) const SizedBox(height: 24),

                      // Capacity management section (only for tutors)
                      if (isTutor) _buildCapacitySection(context, course),

                      if (isTutor) const SizedBox(height: 24),

                      // Schedule section
                      _buildScheduleSection(context, course),

                      // Add task section
                      const SizedBox(height: 24),
                      _buildTasksSection(context, course.id),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner(BuildContext context, Course course) {
    return Container(
      height: 120,
      width: double.infinity,
      color: _getSubjectColor(course.subject),
      child: Stack(
        children: [
          // Subject icon in the background
          Positioned(
            right: 20,
            bottom: -10,
            child: Icon(
              _getSubjectIcon(course.subject),
              size: 100,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          // Course info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  course.subject,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Grade ${course.grade}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfoCard(BuildContext context, Course course) {
    // Check if user is a tutor to show active status toggle
    final authState = context.read<AuthBloc>().state;
    final isTutor = authState is Authenticated && authState.isTutor;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Course Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isTutor)
                  // Add active status badge with toggle functionality
                  GestureDetector(
                    onTap: () => _toggleCourseActiveStatus(context, course),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: course.isActive
                            ? AppColors.success.withOpacity(0.2)
                            : AppColors.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            course.isActive ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: course.isActive
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            course.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: course.isActive
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Tutor', course.tutorName),
            const SizedBox(height: 8),
            _buildInfoRow('Subject', course.subject),
            const SizedBox(height: 8),
            _buildInfoRow('Grade', 'Grade ${course.grade}'),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Sessions',
              '${course.schedules.length} per week',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Enrollment',
              '${course.enrollmentCount} of ${course.capacity} students',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(width: 100),
                // Match the width of the label in _buildInfoRow
                Expanded(
                  child: CapacityIndicator(course: course),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Add this method to handle toggling the course active status
  void _toggleCourseActiveStatus(BuildContext context, Course course) {
    // Store a reference to the CourseBloc
    final courseBloc = context.read<CourseBloc>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          course.isActive ? 'Deactivate Course' : 'Activate Course',
        ),
        content: Text(
          course.isActive
              ? 'This will hide the course from students. Are you sure you want to deactivate this course?'
              : 'This will make the course visible to enrolled students. Are you sure you want to activate this course?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              courseBloc.add(
                UpdateCourseActiveStatusEvent(
                  courseId: course.id,
                  isActive: !course.isActive,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  course.isActive ? AppColors.error : AppColors.success,
            ),
            child: Text(course.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorActionsSection(BuildContext context, Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tutor Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/tutor/courses/${course.id}/tasks',
                      extra: course.subject);
                },
                icon: const Icon(Icons.assignment),
                label: const Text('Manage Tasks'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Replace the existing Attendance button in the tutor actions section
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _navigateToAttendanceManagement,
                icon: const Icon(Icons.people),
                label: const Text('Attendance'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to manage enrollment screen
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Manage Enrollment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentTeal,
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildCapacitySection(BuildContext context, Course course) {
    final capacityPercentage = course.enrollmentPercentage;
    final isNearCapacity = course.isNearCapacity;
    final isAtCapacity = course.isAtCapacity;

    // Determine the color based on capacity
    Color capacityColor =
        AppColors.success; // Default: Green for low enrollment
    if (isAtCapacity) {
      capacityColor = AppColors.error; // Red for at capacity
    } else if (isNearCapacity) {
      capacityColor = AppColors.warning; // Orange/yellow for near capacity
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Class Capacity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Capacity',
                  onPressed: () => _showCapacityEditDialog(context, course),
                  color: AppColors.primaryBlue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Enrollment status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Enrollment:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${course.enrollmentCount} of ${course.capacity} students',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: capacityColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Capacity progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: capacityPercentage / 100,
                minHeight: 10,
                backgroundColor: AppColors.backgroundDark,
                color: capacityColor,
              ),
            ),
            const SizedBox(height: 8),
            // Status text
            Text(
              _getCapacityStatusText(course),
              style: TextStyle(
                color: capacityColor,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    );
  }

  String _getCapacityStatusText(Course course) {
    if (course.isAtCapacity) {
      return 'Class is at full capacity';
    } else if (course.isNearCapacity) {
      return 'Class is nearly full';
    } else if (course.enrollmentCount > 0) {
      return 'Class has space available';
    } else {
      return 'No students enrolled yet';
    }
  }

  void _showCapacityEditDialog(BuildContext context, Course course) {
    // Use our new bottom sheet component instead of a dialog
    CapacityEditBottomSheet.show(
      context: context,
      course: course,
    );
  }

  // void _showCapacityEditDialog(BuildContext context, Course course) {
  //   final TextEditingController capacityController = TextEditingController();
  //   capacityController.text = course.capacity.toString();
  //   final formKey = GlobalKey<FormState>(); // Add a form key for validation
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Update Class Capacity'),
  //       content: Form(
  //         key: formKey,
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               'Current enrollment: ${course.enrollmentCount} students',
  //               style: TextStyle(color: AppColors.textMedium),
  //             ),
  //             const SizedBox(height: 16),
  //             TextFormField(
  //               controller: capacityController,
  //               keyboardType: TextInputType.number,
  //               decoration: const InputDecoration(
  //                 labelText: 'New Capacity',
  //                 hintText: 'Enter a number greater than current enrollment',
  //                 border: OutlineInputBorder(),
  //               ),
  //               validator: (value) {
  //                 if (value == null || value.isEmpty) {
  //                   return 'Please enter a capacity value';
  //                 }
  //
  //                 final int? capacity = int.tryParse(value);
  //                 if (capacity == null) {
  //                   return 'Please enter a valid number';
  //                 }
  //
  //                 if (capacity < 1) {
  //                   return 'Capacity must be at least 1';
  //                 }
  //
  //                 if (capacity < course.enrollmentCount) {
  //                   return 'Capacity cannot be less than current enrollment (${course.enrollmentCount})';
  //                 }
  //
  //                 return null;
  //               },
  //             ),
  //             const SizedBox(height: 8),
  //             Text(
  //               'Note: Capacity cannot be less than current enrollment.',
  //               style: TextStyle(
  //                 color: AppColors.textMedium,
  //                 fontSize: 12,
  //                 fontStyle: FontStyle.italic,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             // Use the form validation
  //             if (formKey.currentState!.validate()) {
  //               final int newCapacity = int.parse(capacityController.text);
  //               Navigator.pop(context);
  //               context.read<CourseBloc>().add(
  //                     UpdateCourseCapacityEvent(
  //                       courseId: course.id,
  //                       capacity: newCapacity,
  //                     ),
  //                   );
  //             }
  //           },
  //           child: const Text('Update'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildScheduleSection(BuildContext context, Course course) {
    // Check if user is a tutor to show edit buttons
    final authState = context.read<AuthBloc>().state;
    final isTutor = authState is Authenticated && authState.isTutor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Class Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isTutor)
              ElevatedButton.icon(
                onPressed: () => _showAddScheduleDialog(context, course.id),
                icon: const Icon(Icons.add),
                label: const Text('Add Schedule'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (course.schedules.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No scheduled classes yet',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: course.schedules.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final schedule = course.schedules[index];
              return _buildScheduleCard(context, schedule, isTutor, course.id);
            },
          ),
      ],
    );
  }

  Widget _buildScheduleCard(
      BuildContext context, Schedule schedule, bool isTutor, String courseId) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getSubjectColor(schedule.subject).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    schedule.day,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getSubjectColor(schedule.subject),
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textMedium,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
                  style: TextStyle(
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textMedium,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      schedule.location,
                      style: TextStyle(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
                if (isTutor)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditScheduleDialog(
                            context, courseId, schedule),
                        color: AppColors.primaryBlue,
                        tooltip: 'Edit Schedule',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _confirmDeleteSchedule(
                            context, courseId, schedule.id),
                        color: AppColors.error,
                        tooltip: 'Delete Schedule',
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context, String courseId) {
    // Store a reference to the CourseBloc before creating the dialog
    final courseBloc = context.read<CourseBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => ScheduleDialog(
        courseId: courseId,
        onSave: (day, startTime, endTime, location) {
          // Create DateTime objects from TimeOfDay
          final now = DateTime.now();
          final startDateTime = DateTime(
              now.year, now.month, now.day, startTime.hour, startTime.minute);
          final endDateTime = DateTime(
              now.year, now.month, now.day, endTime.hour, endTime.minute);

          // Create Schedule entity
          final schedule = Schedule(
            id: '$courseId-schedule-new',
            courseId: courseId,
            day: day,
            startTime: startDateTime,
            endTime: endDateTime,
            location: location,
            subject: 'Subject',
            // This will be filled by the repository
            grade: 0, // This will be filled by the repository
          );

          // Use the stored courseBloc reference
          courseBloc.add(
            AddScheduleEvent(
              courseId: courseId,
              schedule: schedule,
            ),
          );
        },
      ),
    );
  }

  void _showEditScheduleDialog(
      BuildContext context, String courseId, Schedule schedule) {
    // Store a reference to the CourseBloc
    final courseBloc = context.read<CourseBloc>();

    showDialog(
      context: context,
      builder: (context) => ScheduleDialog(
        existingSchedule: schedule,
        courseId: courseId,
        onSave: (day, startTime, endTime, location) {
          // Create DateTime objects from TimeOfDay
          final now = DateTime.now();
          final startDateTime = DateTime(
              now.year, now.month, now.day, startTime.hour, startTime.minute);
          final endDateTime = DateTime(
              now.year, now.month, now.day, endTime.hour, endTime.minute);

          // Create updated Schedule entity
          final updatedSchedule = Schedule(
            id: schedule.id,
            courseId: courseId,
            day: day,
            startTime: startDateTime,
            endTime: endDateTime,
            location: location,
            subject: schedule.subject,
            grade: schedule.grade,
          );

          // Use the stored courseBloc reference
          courseBloc.add(
            UpdateScheduleEvent(
              courseId: courseId,
              scheduleId: schedule.id,
              updatedSchedule: updatedSchedule,
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteSchedule(
      BuildContext context, String courseId, String scheduleId) {
    // Store a reference to the CourseBloc
    final courseBloc = context.read<CourseBloc>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text(
          'Are you sure you want to delete this schedule? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              courseBloc.add(
                DeleteScheduleEvent(
                  courseId: courseId,
                  scheduleId: scheduleId,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection(BuildContext context, String courseId) {
    return BlocProvider(
      create: (context) =>
          getIt<TaskBloc>()..add(LoadTasksByCourseEvent(courseId: courseId)),
      child: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state is TasksLoaded) {
            final tasks = state.tasks;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Course Tasks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (tasks.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          // Navigate to all tasks for this course
                          context.push('/student/tasks?courseId=$courseId');
                        },
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (tasks.isEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No tasks assigned for this course yet',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length > 3 ? 3 : tasks.length,
                    // Show max 3 tasks
                    itemBuilder: (context, index) {
                      return _buildTaskItem(context, tasks[index]);
                    },
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task) {
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
          color: task.isCompleted
              ? AppColors.success
              : isOverdue
                  ? AppColors.error
                  : AppColors.primaryBlue,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          task.dueDate != null
              ? 'Due: ${DateFormat('dd MMM yyyy').format(task.dueDate!)}'
              : 'No due date',
          style: TextStyle(
            color: isOverdue ? AppColors.error : null,
            fontWeight: isOverdue ? FontWeight.bold : null,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.push('/student/tasks/${task.id}');
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return AppColors.mathSubject;
      case 'science':
        return AppColors.scienceSubject;
      case 'english':
        return AppColors.englishSubject;
      case 'bahasa malaysia':
        return AppColors.bahasaSubject;
      case 'chinese':
        return AppColors.chineseSubject;
      default:
        return AppColors.primaryBlue;
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'english':
        return Icons.menu_book;
      case 'bahasa malaysia':
        return Icons.language;
      case 'chinese':
        return Icons.translate;
      default:
        return Icons.school;
    }
  }

  void _navigateToAttendanceManagement() {
    // Use the established router instead of creating a new route
    context.push(
      '/tutor/courses/${widget.courseId}/attendance',
      extra: context.read<CourseBloc>().state is CourseDetailsLoaded
          ? (context.read<CourseBloc>().state as CourseDetailsLoaded)
              .course
              .subject
          : 'Course',
    );
  }
}
