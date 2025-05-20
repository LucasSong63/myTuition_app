import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/core/utils/task_utils.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/student_task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';

class TaskProgressPage extends StatefulWidget {
  final String taskId;

  const TaskProgressPage({
    Key? key,
    required this.taskId,
  }) : super(key: key);

  @override
  State<TaskProgressPage> createState() => _TaskProgressPageState();
}

class _TaskProgressPageState extends State<TaskProgressPage> {
  Task? _task;
  List<StudentTask> _studentTasks = [];

  // Add a map to store student names
  final Map<String, String> _studentNames = {};
  bool _isLoading = true;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    _loadTaskData();
  }

  Future<void> _loadTaskData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = !_isReloading;
      _isReloading = true;
    });

    try {
      // Fetch task details directly from Firestore
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .get();

      if (taskDoc.exists && mounted) {
        final data = taskDoc.data()!;
        setState(() {
          _task = Task(
            id: taskDoc.id,
            courseId: data['courseId'] ?? '',
            title: data['title'] ?? 'Untitled Task',
            description: data['description'] ?? '',
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
            isCompleted: data['isCompleted'] ?? false,
          );
        });

        // Load student tasks directly instead of using BLoC
        await _loadStudentTasks();
      } else if (mounted) {
        // If task doesn't exist
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        print('Error loading task details: $e');
        // Only show error if not in reloading state
        if (!_isReloading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading task details: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isReloading = false;
        });
      }
    }
  }

  Future<void> _loadStudentTasks() async {
    if (!mounted || _task == null) return;

    try {
      // Get the task's course ID
      final String courseId = _task!.courseId;

      // Get all students enrolled in this course
      final courseDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(courseId)
          .get();

      final List<dynamic> enrolledStudentsRaw =
          courseDoc.data()?['students'] ?? [];
      final List<String> enrolledStudents =
          enrolledStudentsRaw.map((s) => s.toString()).toList();

      if (enrolledStudents.isEmpty) {
        setState(() {
          _studentTasks = [];
        });
        return;
      }

      // Get existing student tasks
      final snapshot = await FirebaseFirestore.instance
          .collection('student_tasks')
          .where('taskId', isEqualTo: widget.taskId)
          .get();

      final List<StudentTask> studentTasks = snapshot.docs.map((doc) {
        final data = doc.data();
        return StudentTask(
          id: doc.id,
          taskId: data['taskId'] ?? '',
          studentId: data['studentId'] ?? '',
          remarks: data['remarks'] ?? '',
          isCompleted: data['isCompleted'] ?? false,
          completedAt: data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
        );
      }).toList();

      // Create a map of existing student tasks for quick lookup
      final Map<String, StudentTask> existingTasksMap = {
        for (var task in studentTasks) task.studentId: task
      };

      // Create placeholder tasks for students who don't have one yet
      List<StudentTask> allStudentTasks = [];

      for (String studentId in enrolledStudents) {
        if (existingTasksMap.containsKey(studentId)) {
          // Use existing task
          allStudentTasks.add(existingTasksMap[studentId]!);
        } else {
          // Create a placeholder task
          final studentTask = StudentTask(
            id: '$widget.taskId-$studentId',
            taskId: widget.taskId,
            studentId: studentId,
            remarks: '',
            isCompleted: false,
          );
          allStudentTasks.add(studentTask);
        }
      }

      if (mounted) {
        setState(() {
          _studentTasks = allStudentTasks;
        });

        // Load student names
        _loadStudentNames(enrolledStudents);
      }
    } catch (e) {
      print('Error loading student tasks: $e');
    }
  }

  // Load student names from Firestore based on student IDs
  Future<void> _loadStudentNames(List<String> studentIds) async {
    try {
      // Clear existing names
      _studentNames.clear();

      // For each student ID, fetch the name from Firebase
      for (final studentId in studentIds) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .where('studentId', isEqualTo: studentId)
            .limit(1)
            .get();

        if (userDoc.docs.isNotEmpty) {
          final userData = userDoc.docs.first.data();
          _studentNames[studentId] = userData['name'] ?? 'Unknown Student';
        } else {
          _studentNames[studentId] = 'Student $studentId';
        }
      }

      // Update the UI if component is still mounted
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading student names: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Progress'),
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );

            // Wait before reloading to ensure Firestore has updated
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _loadTaskData();
              }
            });
          }

          if (state is TaskError) {
            // Only show errors that are not from the reloading process
            if (!_isReloading) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _task == null
                ? Center(
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
                          'Task not found',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTaskData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _buildContent(),
      ),
      bottomSheet: _task != null && _studentTasks.isNotEmpty
          ? Container(
              width: double.infinity,
              color: _task!.isCompleted ? AppColors.success : null,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Text(
                _task!.isCompleted ? 'Task marked as completed' : '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task details card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _task?.title ?? 'Task Details',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _task?.description ?? '',
                    style: TextStyle(
                      color: AppColors.textMedium,
                    ),
                  ),
                  if (_task?.dueDate != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 16,
                          color: TaskUtils.isTaskOverdue(_task!.dueDate!, false)
                              ? AppColors.error
                              : AppColors.textMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Due: ${TaskUtils.shortDateFormat.format(_task!.dueDate!)}',
                          style: TextStyle(
                            color:
                                TaskUtils.isTaskOverdue(_task!.dueDate!, false)
                                    ? AppColors.error
                                    : AppColors.textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Progress header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Student Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_getCompletedCount()} / ${_studentTasks.length} completed',
                style: TextStyle(
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),

        // Progress list
        Expanded(
          child:
              _studentTasks.isEmpty ? _buildEmptyState() : _buildStudentList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'No student progress available',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Students need to be enrolled in this course',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _studentTasks.length,
      itemBuilder: (context, index) {
        final studentTask = _studentTasks[index];
        return _buildStudentTaskCard(studentTask);
      },
    );
  }

  Widget _buildStudentTaskCard(StudentTask studentTask) {
    // Get student name from our map, or use student ID if name not found
    final studentName = _studentNames[studentTask.studentId] ??
        'Student ${studentTask.studentId}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student name and toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        studentTask.studentId,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: studentTask.isCompleted,
                  activeColor: AppColors.success,
                  onChanged: (value) {
                    if (value) {
                      _markTaskAsCompleted(studentTask);
                    } else {
                      _markTaskAsIncomplete(studentTask);
                    }
                  },
                ),
              ],
            ),

            // Completion status
            Row(
              children: [
                Icon(
                  studentTask.isCompleted ? Icons.check_circle : Icons.pending,
                  color: studentTask.isCompleted
                      ? AppColors.success
                      : AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  studentTask.isCompleted ? 'Completed' : 'Pending',
                  style: TextStyle(
                    color: studentTask.isCompleted
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
                if (studentTask.completedAt != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'on ${TaskUtils.completedDateFormat.format(studentTask.completedAt!)}',
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Remarks section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Remarks',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    size: 20,
                  ),
                  onPressed: () => _showRemarksDialog(studentTask),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              studentTask.remarks.isEmpty
                  ? 'No remarks yet'
                  : studentTask.remarks,
              style: TextStyle(
                color: studentTask.remarks.isEmpty ? AppColors.textLight : null,
                fontStyle:
                    studentTask.remarks.isEmpty ? FontStyle.italic : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemarksDialog(StudentTask studentTask) {
    final remarksController = TextEditingController(text: studentTask.remarks);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Remarks for ${_studentNames[studentTask.studentId] ?? studentTask.studentId}'),
        content: TextField(
          controller: remarksController,
          decoration: const InputDecoration(
            hintText: 'Add remarks for this student',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateRemarks(studentTask, remarksController.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  int _getCompletedCount() {
    return _studentTasks.where((task) => task.isCompleted).length;
  }

  void _markTaskAsCompleted(StudentTask studentTask) {
    // Set reloading flag to prevent error messages during reload
    setState(() {
      _isReloading = true;
    });

    context.read<TaskBloc>().add(
          MarkTaskAsCompletedEvent(
            taskId: studentTask.taskId,
            studentId: studentTask.studentId,
            remarks: studentTask.remarks,
          ),
        );
  }

  void _markTaskAsIncomplete(StudentTask studentTask) {
    // Set reloading flag to prevent error messages during reload
    setState(() {
      _isReloading = true;
    });

    context.read<TaskBloc>().add(
          MarkTaskAsIncompleteEvent(
            taskId: studentTask.taskId,
            studentId: studentTask.studentId,
          ),
        );
  }

  void _updateRemarks(StudentTask studentTask, String remarks) {
    // Set reloading flag to prevent error messages during reload
    setState(() {
      _isReloading = true;
    });

    context.read<TaskBloc>().add(
          AddTaskRemarksEvent(
            taskId: studentTask.taskId,
            studentId: studentTask.studentId,
            remarks: remarks,
          ),
        );
  }
}
