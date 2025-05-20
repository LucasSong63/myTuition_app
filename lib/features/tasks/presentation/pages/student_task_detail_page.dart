import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/core/utils/task_utils.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/student_task.dart';

class StudentTaskDetailPage extends StatefulWidget {
  final String taskId;

  const StudentTaskDetailPage({
    super.key,
    required this.taskId,
  });

  @override
  State<StudentTaskDetailPage> createState() => _StudentTaskDetailPageState();
}

class _StudentTaskDetailPageState extends State<StudentTaskDetailPage> {
  String _studentId = '';
  Task? _task;
  StudentTask? _studentTask;
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Get student ID from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _studentId = authState.user.studentId ?? authState.user.docId;

      // Load task and student task data directly
      _loadTaskData();
    } else {
      setState(() {
        _isError = true;
        _errorMessage = 'User not authenticated';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTaskData() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      // 1. Load task data directly from Firestore
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .get();

      if (!taskDoc.exists) {
        setState(() {
          _isError = true;
          _errorMessage = 'Task not found';
          _isLoading = false;
        });
        return;
      }

      final data = taskDoc.data()!;
      final task = Task(
        id: taskDoc.id,
        courseId: data['courseId'] ?? '',
        title: data['title'] ?? 'Untitled Task',
        description: data['description'] ?? '',
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
        isCompleted: data['isCompleted'] ?? false,
      );

      // 2. Load student-specific task data
      final studentTaskId = '${widget.taskId}-$_studentId';
      final studentTaskDoc = await FirebaseFirestore.instance
          .collection('student_tasks')
          .doc(studentTaskId)
          .get();

      StudentTask? studentTask;
      if (studentTaskDoc.exists) {
        final studentData = studentTaskDoc.data()!;
        studentTask = StudentTask(
          id: studentTaskDoc.id,
          taskId: studentData['taskId'] ?? widget.taskId,
          studentId: studentData['studentId'] ?? _studentId,
          remarks: studentData['remarks'] ?? '',
          isCompleted: studentData['isCompleted'] ?? false,
          completedAt: studentData['completedAt'] != null
              ? (studentData['completedAt'] as Timestamp).toDate()
              : null,
        );
      } else {
        // Create a placeholder student task if none exists
        studentTask = StudentTask(
          id: studentTaskId,
          taskId: widget.taskId,
          studentId: _studentId,
          remarks: '',
          isCompleted: false,
        );
      }

      if (mounted) {
        setState(() {
          _task = task;
          _studentTask = studentTask;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading task data: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Failed to load task details: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is a tutor
    final authState = context.read<AuthBloc>().state;
    final isTutor = authState is Authenticated && authState.isTutor;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Task Details'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Task Details'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadTaskData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_task == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Task Details'),
        ),
        body: const Center(
          child: Text('Task not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task title and completion status
            _buildTaskHeader(_task!, _studentTask, isTutor),

            const SizedBox(height: 24),

            // Task details card
            _buildTaskDetailsCard(_task!, _studentTask?.isCompleted ?? false),

            const SizedBox(height: 24),

            // Tutor remarks
            _buildRemarksCard(_studentTask),
          ],
        ),
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
      ],
    );
  }

  Widget _buildTaskDetailsCard(Task task, bool isCompleted) {
    final dueDate = task.dueDate != null
        ? TaskUtils.longDateFormat.format(task.dueDate!)
        : 'No due date';

    // Check if task is overdue using our utility function
    final bool isOverdue = TaskUtils.isTaskOverdue(task.dueDate, isCompleted);

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
                      const Text(
                        'Due Date',
                        style: TextStyle(
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
                      if (isOverdue && !isCompleted) ...[
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
                      const Text(
                        'Description',
                        style: TextStyle(
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
                      const Text(
                        'Created',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        TaskUtils.longDateFormat.format(task.createdAt),
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
                    'Completed on ${TaskUtils.completedDateFormat.format(studentTask!.completedAt!)}',
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
}
