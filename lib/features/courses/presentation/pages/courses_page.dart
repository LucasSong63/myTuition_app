// lib/features/courses/presentation/pages/courses_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/course.dart';
import '../bloc/course_bloc.dart';
import '../bloc/course_event.dart';
import '../bloc/course_state.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    // Get user ID from auth state
    final authState = context.read<AuthBloc>().state;
    String studentId = '';
    if (authState is Authenticated) {
      studentId = authState.user.studentId ?? ''; // This might be the key value
      print("Student ID from user object: $studentId");
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Reload the courses when the user pulls down
          if (studentId.isNotEmpty) {
            context.read<CourseBloc>().add(
                  LoadEnrolledCoursesEvent(studentId: studentId),
                );
          }
          // Wait a short time to ensure the refresh indicator is shown
          return await Future.delayed(const Duration(milliseconds: 800));
        },
        child: BlocBuilder<CourseBloc, CourseState>(
          builder: (context, state) {
            // Load courses if not already loaded
            if (state is CourseInitial && studentId.isNotEmpty) {
              context.read<CourseBloc>().add(
                    LoadEnrolledCoursesEvent(studentId: studentId),
                  );
            }

            if (state is CourseLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CoursesLoaded) {
              if (state.courses.isEmpty) {
                // Use the ListView and SingleChildScrollView to ensure pull-to-refresh works with empty state
                return ListView(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 100),
                          // Push content down for visibility
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'You are not enrolled in any courses yet',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Contact your tutor to get enrolled',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: state.courses.length,
                itemBuilder: (context, index) {
                  final course = state.courses[index];
                  return _buildCourseCard(context, course);
                },
              );
            }

            if (state is CourseError) {
              // Similar to the empty state, wrap in ListView for pull-to-refresh
              return ListView(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 100),
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.message}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (studentId.isNotEmpty) {
                              context.read<CourseBloc>().add(
                                    LoadEnrolledCoursesEvent(
                                        studentId: studentId),
                                  );
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // Default state
            return const Center(
              child: Text('Loading courses...'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push('/student/courses/${course.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getSubjectColor(course.subject),
                    radius: 24,
                    child: Text(
                      course.subject.isNotEmpty
                          ? course.subject[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.subject,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Grade ${course.grade}',
                          style: TextStyle(
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              if (course.schedules.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Schedule:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildSchedulePreview(context, course),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchedulePreview(BuildContext context, Course course) {
    if (course.schedules.isEmpty) {
      return Text(
        'No scheduled classes yet',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: AppColors.textMedium,
        ),
      );
    }

    // Show just the first schedule as a preview
    final schedule = course.schedules.first;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getSubjectColor(course.subject).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            schedule.day,
            style: TextStyle(
              color: _getSubjectColor(course.subject),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
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
}
