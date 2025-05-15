// lib/features/courses/presentation/pages/student_course_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/courses/domain/entities/course.dart';
import 'package:mytuition/features/courses/domain/entities/schedule.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_bloc.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_event.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_state.dart';
import 'package:mytuition/features/courses/presentation/utils/course_detail_utils.dart';
import 'package:mytuition/features/courses/presentation/widgets/course_tasks_section.dart';

class StudentCourseDetailPage extends StatefulWidget {
  final String courseId;

  const StudentCourseDetailPage({
    Key? key,
    required this.courseId,
  }) : super(key: key);

  @override
  State<StudentCourseDetailPage> createState() =>
      _StudentCourseDetailPageState();
}

class _StudentCourseDetailPageState extends State<StudentCourseDetailPage> {
  final GetIt getIt = GetIt.instance;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CourseBloc, CourseState>(
      listener: (context, state) {
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
                      _buildCourseInfoCard(course),

                      const SizedBox(height: 24),

                      // Schedule section
                      _buildScheduleSection(context, course),

                      // Add task section
                      const SizedBox(height: 24),
                      CourseTasksSection(
                        courseId: course.id,
                        isTutor: false,
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

  Widget _buildCourseInfoCard(Course course) {
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
            const Text(
              'Course Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
            if (!course.isActive) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This course is currently inactive. Please contact your tutor for more information.',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
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
    );
  }

  Widget _buildScheduleSection(BuildContext context, Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Class Schedule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
              return _buildScheduleCard(schedule);
            },
          ),
      ],
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
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
          ],
        ),
      ),
    );
  }
}
