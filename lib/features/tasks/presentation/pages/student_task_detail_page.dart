import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/student_task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';

class StudentTaskDetailPage extends StatefulWidget {
  final String taskId;

  const StudentTaskDetailPage({
    Key? key,
    required this.taskId,
  }) : super(key: key);

  @override
  State<StudentTaskDetailPage> createState() => _StudentTaskDetailPageState();
}

class _StudentTaskDetailPageState extends State<StudentTaskDetailPage> {
  String _studentId = '';

  @override
  void initState() {
    super.initState();

    // Get student ID from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _studentId = authState.user.studentId ?? authState.user.id;

      // Add debug info
      print('Loading task detail page for:');
      print('Task ID: ${widget.taskId}');
      print('Student ID: $_studentId');

      // Load student-specific task details
      context.read<TaskBloc>().add(
            LoadStudentTaskEvent(
              taskId: widget.taskId,
              studentId: _studentId,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is a tutor
    final authState = context.read<AuthBloc>().state;
    final isTutor = authState is Authenticated && authState.isTutor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          // Your existing listener code
        },
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StudentTaskLoaded) {
            final task = state.task;
            final studentTask = state.studentTask;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task title and completion status
                  _buildTaskHeader(task, studentTask, isTutor),
                  // Pass isTutor parameter

                  const SizedBox(height: 24),

                  // Task details card
                  _buildTaskDetailsCard(task),

                  const SizedBox(height: 24),

                  // Tutor remarks
                  _buildRemarksCard(studentTask),
                ],
              ),
            );
          }

          // Default or error state
          return const Center(
            child: Text('Failed to load task details'),
          );
        },
      ),
    );
  }

  Widget _buildTaskHeader(Task task, StudentTask? studentTask, bool isTutor) {
    final isCompleted = studentTask?.isCompleted ?? false;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.pending,
                    color: isCompleted ? AppColors.success : AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isCompleted ? 'Completed' : 'Pending',
                    style: TextStyle(
                      color:
                          isCompleted ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Only show the toggle completion button for tutors
        if (isTutor)
          ElevatedButton.icon(
            onPressed: () => _toggleCompletionStatus(studentTask),
            icon: Icon(isCompleted ? Icons.close : Icons.check),
            label: Text(isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isCompleted ? AppColors.error : AppColors.success,
            ),
          ),
      ],
    );
  }

  Widget _buildTaskDetailsCard(Task task) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final dueDate =
        task.dueDate != null ? dateFormat.format(task.dueDate!) : 'No due date';

    // Check if task is overdue
    final bool isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Due date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.event,
                  size: 20,
                  color: isOverdue ? AppColors.error : AppColors.textMedium,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Date',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dueDate,
                        style: TextStyle(
                          color: isOverdue ? AppColors.error : null,
                          fontWeight: isOverdue ? FontWeight.bold : null,
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Overdue!',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.description,
                  size: 20,
                  color: AppColors.textMedium,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description.isEmpty
                            ? 'No description provided'
                            : task.description,
                        style: TextStyle(
                          color: task.description.isEmpty
                              ? AppColors.textLight
                              : null,
                          fontStyle: task.description.isEmpty
                              ? FontStyle.italic
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Created date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: AppColors.textMedium,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(task.createdAt),
                        style: TextStyle(
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksCard(StudentTask? studentTask) {
    final remarks = studentTask?.remarks ?? '';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tutor Remarks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              remarks.isEmpty ? 'No remarks from tutor yet' : remarks,
              style: TextStyle(
                color: remarks.isEmpty ? AppColors.textLight : null,
                fontStyle: remarks.isEmpty ? FontStyle.italic : null,
              ),
            ),
            if (studentTask?.completedAt != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Completed on ${DateFormat('dd MMM yyyy').format(studentTask!.completedAt!)}',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleCompletionStatus(StudentTask? studentTask) {
    if (studentTask == null) {
      // If no student task exists, create one and mark as completed
      context.read<TaskBloc>().add(
            MarkTaskAsCompletedEvent(
              taskId: widget.taskId,
              studentId: _studentId,
            ),
          );
    } else {
      // Toggle existing status
      if (studentTask.isCompleted) {
        context.read<TaskBloc>().add(
              MarkTaskAsIncompleteEvent(
                taskId: widget.taskId,
                studentId: _studentId,
              ),
            );
      } else {
        context.read<TaskBloc>().add(
              MarkTaskAsCompletedEvent(
                taskId: widget.taskId,
                studentId: _studentId,
                remarks: studentTask.remarks,
              ),
            );
      }
    }
  }
}
