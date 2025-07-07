// lib/features/courses/presentation/widgets/course_tasks_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/tasks/domain/entities/task.dart';
import 'package:mytuition/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:mytuition/features/tasks/presentation/bloc/task_event.dart';
import 'package:mytuition/features/tasks/presentation/bloc/task_state.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';

class CourseTasksSection extends StatelessWidget {
  final String courseId;
  final bool isTutor;
  final GetIt getIt = GetIt.instance;

  CourseTasksSection({
    Key? key,
    required this.courseId,
    required this.isTutor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<TaskBloc>()..add(LoadTasksByCourseEvent(courseId: courseId)),
      child: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Loading tasks...',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is TaskError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 10.w,
                      color: AppColors.error,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Failed to load tasks',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.error,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextButton(
                      onPressed: () => context.read<TaskBloc>().add(
                            LoadTasksByCourseEvent(courseId: courseId),
                          ),
                      child: Text(
                        'Retry',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is TasksLoaded) {
            final tasks = state.tasks;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: AppColors.accentTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(2.w),
                          ),
                          child: Icon(
                            Icons.assignment_outlined,
                            color: AppColors.accentTeal,
                            size: 5.w,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Course Tasks',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (tasks.isNotEmpty) ...[
                          SizedBox(width: 2.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3.w),
                            ),
                            child: Text(
                              '${tasks.length}',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (tasks.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          // Navigate to all tasks for this course
                          if (isTutor) {
                            context.push('/tutor/courses/$courseId/tasks');
                          } else {
                            context.push('/student/tasks?courseId=$courseId');
                          }
                        },
                        icon: Icon(Icons.arrow_forward, size: 4.w),
                        label: Text(
                          'View All',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Tasks list or empty state
                if (tasks.isEmpty)
                  _buildEmptyState()
                else
                  _buildTasksList(tasks, context),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
        side: BorderSide(
          color: AppColors.backgroundDark.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_late_outlined,
                size: 12.w,
                color: AppColors.textLight,
              ),
              SizedBox(height: 2.h),
              Text(
                'No tasks assigned yet',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                isTutor
                    ? 'Create tasks to help students practice'
                    : 'Your tutor will assign tasks soon',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksList(List<Task> tasks, BuildContext context) {
    // Show max 3 tasks in the preview
    final displayTasks = tasks.take(3).toList();
    final remainingCount = tasks.length - displayTasks.length;

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayTasks.length,
          separatorBuilder: (context, index) => SizedBox(height: 2.h),
          itemBuilder: (context, index) {
            return _buildTaskItem(context, displayTasks[index]);
          },
        ),
        if (remainingCount > 0) ...[
          SizedBox(height: 2.h),
          Card(
            elevation: 0,
            color: AppColors.primaryBlue.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: InkWell(
              onTap: () {
                if (isTutor) {
                  context.push('/tutor/courses/$courseId/tasks');
                } else {
                  context.push('/student/tasks?courseId=$courseId');
                }
              },
              borderRadius: BorderRadius.circular(2.w),
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.more_horiz,
                      color: AppColors.primaryBlue,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'View $remainingCount more ${remainingCount == 1 ? 'task' : 'tasks'}',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task) {
    // For students, get their specific completion status
    bool isTaskCompleted = task.isCompleted;
    String? studentId;

    if (!isTutor) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        studentId = authState.user.studentId;
      }
    }

    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !isTaskCompleted;

    final daysLeft = task.dueDate != null
        ? task.dueDate!.difference(DateTime.now()).inDays
        : null;

    // Determine status color and icon based on role
    Color statusColor;
    IconData statusIcon;
    String statusText = '';

    if (isTutor) {
      // For tutor: show general task status
      if (task.isCompleted) {
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'Completed by some students';
      } else if (isOverdue) {
        statusColor = AppColors.error;
        statusIcon = Icons.error;
        statusText = 'Overdue';
      } else if (daysLeft != null && daysLeft <= 2) {
        statusColor = AppColors.warning;
        statusIcon = Icons.warning;
        statusText = daysLeft == 0
            ? 'Due Today'
            : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left';
      } else {
        statusColor = AppColors.primaryBlue;
        statusIcon = Icons.circle_outlined;
        statusText = daysLeft != null ? '$daysLeft days left' : 'No due date';
      }
    } else {
      // For student: show their personal completion status
      // Note: This is using the general completion status for now
      // In a real implementation, you'd check the student_tasks collection
      if (isTaskCompleted) {
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
      } else if (isOverdue) {
        statusColor = AppColors.error;
        statusIcon = Icons.error;
        statusText = 'Overdue';
      } else if (daysLeft != null && daysLeft <= 2) {
        statusColor = AppColors.warning;
        statusIcon = Icons.warning;
        statusText = daysLeft == 0
            ? 'Due Today'
            : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left';
      } else {
        statusColor = AppColors.primaryBlue;
        statusIcon = Icons.circle_outlined;
        statusText = daysLeft != null ? '$daysLeft days left' : 'No due date';
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to appropriate route based on user role
          if (isTutor) {
            context.push('/tutor/tasks/${task.id}');
          } else {
            context.push('/student/tasks/${task.id}');
          }
        },
        borderRadius: BorderRadius.circular(3.w),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              // Status icon with background
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 3.w),

              // Task details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                        decoration: isTaskCompleted && !isTutor
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 3.5.w,
                          color: AppColors.textMedium,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          task.dueDate != null
                              ? DateFormat('dd MMM yyyy').format(task.dueDate!)
                              : 'No due date',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textMedium,
                          ),
                        ),
                        if (statusText.isNotEmpty) ...[
                          SizedBox(width: 2.w),
                          Text('•',
                              style: TextStyle(color: AppColors.textMedium)),
                          SizedBox(width: 2.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 1.5.w,
                              vertical: 0.3.h,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(1.w),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (task.description.isNotEmpty) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textMedium,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // For tutor, show completion stats
                    if (isTutor && studentId == null) ...[
                      SizedBox(height: 0.5.h),
                      FutureBuilder<Map<String, int>>(
                        future: _getTaskCompletionStats(context, task.id),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final stats = snapshot.data!;
                            final completed = stats['completed'] ?? 0;
                            final total = stats['total'] ?? 0;

                            return Text(
                              'Completion: $completed/$total students',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.textMedium,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }
                          return SizedBox.shrink();
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 4.w,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get task completion statistics for tutors
  Future<Map<String, int>> _getTaskCompletionStats(
      BuildContext context, String taskId) async {
    // In a real implementation, this would query the student_tasks collection
    // to get actual completion stats
    // For now, returning mock data
    return {
      'completed': 0,
      'total': 0,
    };
  }
}
