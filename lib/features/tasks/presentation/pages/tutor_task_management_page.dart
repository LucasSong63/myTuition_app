import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../widgets/add_task_dialog.dart';

class TutorTaskManagementPage extends StatefulWidget {
  final String courseId;
  final String courseName;

  const TutorTaskManagementPage({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  State<TutorTaskManagementPage> createState() =>
      _TutorTaskManagementPageState();
}

class _TutorTaskManagementPageState extends State<TutorTaskManagementPage> {
  late String courseId;
  late String courseName;

  @override
  void initState() {
    super.initState();
    courseId = widget.courseId;
    courseName = widget.courseName;

    // Use a small delay to ensure the BLoC is properly initialized before loading tasks
    // This helps with the initial navigation to the page
    Future.microtask(() {
      if (mounted) {
        context.read<TaskBloc>().add(
              LoadTasksByCourseEvent(courseId: courseId),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$courseName Tasks'),
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          }
          if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          // Show loading indicator for initial load and explicit loading state
          if (state is TaskInitial || state is TaskLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Show tasks if loaded successfully
          if (state is TasksLoaded) {
            final tasks = state.tasks;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildAddTaskButton(context),
                ),
                Expanded(
                  child: tasks.isEmpty
                      ? _buildEmptyState()
                      : _buildTaskList(context, tasks),
                ),
              ],
            );
          }

          // Handle error state with retry button
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Failed to load tasks. Please try again.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<TaskBloc>().add(
                          LoadTasksByCourseEvent(courseId: courseId),
                        );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Add New Task',
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
            'No tasks available',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add tasks for students to see what they need to do',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, List<Task> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(context, task);
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final dueDate = task.dueDate != null
        ? 'Due: ${dateFormat.format(task.dueDate!)}'
        : 'No due date';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to task details/student progress
          context.push('/tutor/tasks/${task.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDeleteTask(context, task),
                    color: AppColors.error,
                    tooltip: 'Delete Task',
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dueDate,
                    style: TextStyle(
                      color: task.dueDate != null &&
                              task.dueDate!.isBefore(DateTime.now())
                          ? AppColors.error
                          : AppColors.textMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.people),
                    label: const Text('View Progress'),
                    onPressed: () {
                      context.push('/tutor/tasks/${task.id}');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddTaskButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showAddTaskDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('Add New Task'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<TaskBloc>(), // Pass the existing TaskBloc
        child: AddTaskDialog(
          courseId: courseId,
          courseName: courseName,
        ),
      ),
    );
  }

  void _confirmDeleteTask(BuildContext context, Task task) {
    // Store a reference to the TaskBloc before showing the dialog
    final taskBloc = context.read<TaskBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text(
          'Are you sure you want to delete "${task.title}"? This action cannot be undone and all student progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Deleting task...'),
                  duration: Duration(seconds: 1),
                ),
              );

              // Use the stored taskBloc reference
              taskBloc.add(DeleteTaskEvent(
                taskId: task.id,
                courseId: task.courseId,
              ));
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
}
