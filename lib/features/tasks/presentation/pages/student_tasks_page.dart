import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';

class StudentTasksPage extends StatelessWidget {
  const StudentTasksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the student ID from auth state
    final authState = context.read<AuthBloc>().state;
    String studentId = '';
    if (authState is Authenticated) {
      studentId = authState.user.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          // Load tasks if not already loaded
          if (state is TaskInitial && studentId.isNotEmpty) {
            context.read<TaskBloc>().add(
                  LoadTasksForStudentEvent(studentId: studentId),
                );
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TasksLoaded) {
            final tasks = state.tasks;

            if (tasks.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                if (studentId.isNotEmpty) {
                  context.read<TaskBloc>().add(
                        LoadTasksForStudentEvent(studentId: studentId),
                      );
                }
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return _buildTaskCard(context, task, studentId);
                },
              ),
            );
          }

          // Error or default state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load tasks',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (studentId.isNotEmpty) {
                      context.read<TaskBloc>().add(
                            LoadTasksForStudentEvent(studentId: studentId),
                          );
                    }
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'No tasks assigned',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any tasks assigned yet',
            style: TextStyle(
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task, String studentId) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final dueDate =
        task.dueDate != null ? dateFormat.format(task.dueDate!) : 'No due date';

    // Check if due date is in the past
    final bool isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push('/student/tasks/${task.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Subject indicator (color dot)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getSubjectColor(task.courseId),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Task title
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Completion status
                  Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: task.isCompleted
                        ? AppColors.success
                        : isOverdue
                            ? AppColors.error
                            : AppColors.textMedium,
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: TextStyle(
                    color: AppColors.textMedium,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Due date
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 16,
                        color:
                            isOverdue ? AppColors.error : AppColors.textMedium,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dueDate,
                        style: TextStyle(
                          color: isOverdue
                              ? AppColors.error
                              : AppColors.textMedium,
                          fontWeight:
                              isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  // Status text
                  Text(
                    task.isCompleted
                        ? 'Completed'
                        : isOverdue
                            ? 'Overdue'
                            : 'Pending',
                    style: TextStyle(
                      color: task.isCompleted
                          ? AppColors.success
                          : isOverdue
                              ? AppColors.error
                              : AppColors.textMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String courseId) {
    // This is a placeholder. In a real app, you'd map course IDs to subjects
    // and then map subjects to colors
    final colors = [
      AppColors.mathSubject,
      AppColors.scienceSubject,
      AppColors.englishSubject,
      AppColors.bahasaSubject,
      AppColors.chineseSubject,
    ];

    // A simple hash function to get a consistent color for the same courseId
    int hash = 0;
    for (var i = 0; i < courseId.length; i++) {
      hash = (hash + courseId.codeUnitAt(i)) % colors.length;
    }

    return colors[hash];
  }
}
