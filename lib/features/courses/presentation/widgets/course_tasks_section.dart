// lib/features/courses/presentation/widgets/course_tasks_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/tasks/domain/entities/task.dart';
import 'package:mytuition/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:mytuition/features/tasks/presentation/bloc/task_event.dart';
import 'package:mytuition/features/tasks/presentation/bloc/task_state.dart';

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
                          // Use tutor or student route based on user role
                          if (isTutor) {
                            // Use tutor tasks route
                            context.push('/tutor/courses/$courseId/tasks');
                          } else {
                            // Use student tasks route with query parameter
                            context.push('/student/tasks?courseId=$courseId');
                          }
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
          // Navigate to appropriate route based on user role
          if (isTutor) {
            // Use tutor task progress route
            context.push('/tutor/tasks/${task.id}');
          } else {
            // Use student task detail route
            context.push('/student/tasks/${task.id}');
          }
        },
      ),
    );
  }
}
