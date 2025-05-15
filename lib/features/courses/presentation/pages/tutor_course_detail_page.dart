// lib/features/courses/presentation/pages/tutor_course_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/courses/domain/entities/course.dart';
import 'package:mytuition/features/courses/domain/entities/schedule.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_bloc.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_event.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_state.dart';
import 'package:mytuition/features/courses/presentation/utils/course_detail_utils.dart';
import 'package:mytuition/features/courses/presentation/widgets/capacity_edit_bottom_sheet.dart';
import 'package:mytuition/features/courses/presentation/widgets/course_tasks_section.dart';
import 'package:mytuition/features/courses/presentation/widgets/schedule_dialog.dart';

class TutorCourseDetailPage extends StatefulWidget {
  final String courseId;

  const TutorCourseDetailPage({
    Key? key,
    required this.courseId,
  }) : super(key: key);

  @override
  State<TutorCourseDetailPage> createState() => _TutorCourseDetailPageState();
}

class _TutorCourseDetailPageState extends State<TutorCourseDetailPage> {
  final GetIt getIt = GetIt.instance;

  @override
  Widget build(BuildContext context) {
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
            backgroundColor: CourseDetailUtils.getSubjectColor(course.subject),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero banner
                CourseDetailUtils.buildHeroBanner(context, course),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course info card
                      _buildCourseInfoCard(context, course),

                      const SizedBox(height: 24),

                      // Tutor actions section
                      _buildTutorActionsSection(context, course),

                      const SizedBox(height: 24),

                      // Schedule section
                      _buildScheduleSection(context, course),

                      // Add task section
                      const SizedBox(height: 24),
                      CourseTasksSection(
                        courseId: course.id,
                        isTutor: true,
                      ),
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

  Widget _buildCourseInfoCard(BuildContext context, Course course) {
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
                // Add active status badge with toggle functionality
                GestureDetector(
                  onTap: () => _toggleCourseActiveStatus(context, course),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            CourseDetailUtils.buildInfoRow('Tutor', course.tutorName),
            const SizedBox(height: 8),
            CourseDetailUtils.buildInfoRow('Subject', course.subject),
            const SizedBox(height: 8),
            CourseDetailUtils.buildInfoRow('Grade', 'Grade ${course.grade}'),
            const SizedBox(height: 8),
            CourseDetailUtils.buildInfoRow(
              'Sessions',
              '${course.schedules.length} per week',
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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _navigateToAttendanceManagement(context),
                icon: const Icon(Icons.people),
                label: const Text('Attendance'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildCapacitySection(context, course),
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
                  onPressed: () => CapacityEditBottomSheet.show(
                    context: context,
                    course: course,
                  ),
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
              CourseDetailUtils.getCapacityStatusText(course),
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

  Widget _buildScheduleSection(BuildContext context, Course course) {
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
              return _buildScheduleCard(context, schedule, course.id);
            },
          ),
      ],
    );
  }

  Widget _buildScheduleCard(
      BuildContext context, Schedule schedule, String courseId) {
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
                    color: CourseDetailUtils.getSubjectColor(schedule.subject)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    schedule.day,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          CourseDetailUtils.getSubjectColor(schedule.subject),
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
                  '${CourseDetailUtils.formatTime(schedule.startTime)} - ${CourseDetailUtils.formatTime(schedule.endTime)}',
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () =>
                          _showEditScheduleDialog(context, courseId, schedule),
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

  void _navigateToAttendanceManagement(BuildContext context) {
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
