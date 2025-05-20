import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/core/utils/task_utils.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import 'package:mytuition/features/tasks/domain/entities/student_task.dart';
import 'package:mytuition/features/tasks/domain/entities/task_with_status.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskFilter { all, pending, completed }

class StudentTasksPage extends StatefulWidget {
  const StudentTasksPage({Key? key}) : super(key: key);

  @override
  State<StudentTasksPage> createState() => _StudentTasksPageState();
}

class _StudentTasksPageState extends State<StudentTasksPage> {
  TaskFilter _currentFilter = TaskFilter.all;
  String? _courseIdFilter; // If we want to filter by course later
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<TaskWithStatus> _allTasksWithStatus = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Schedule loading after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudentTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentTasks() async {
    setState(() {
      _isLoading = true;
    });

    // Get the student ID from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      String studentId = '';

      // If your User entity has a studentId field
      if (authState.user.studentId != null &&
          authState.user.studentId!.isNotEmpty) {
        studentId = authState.user.studentId!;
      } else {
        // Otherwise, fall back to the user's ID
        studentId = authState.user.docId;
      }

      print('Loading tasks for student ID: $studentId');

      try {
        // 1. Get courses the student is enrolled in
        final courseSnapshot = await FirebaseFirestore.instance
            .collection('classes')
            .where('students', arrayContains: studentId)
            .get();

        final courseIds = courseSnapshot.docs.map((doc) => doc.id).toList();

        // No courses found
        if (courseIds.isEmpty) {
          setState(() {
            _allTasksWithStatus = [];
            _isLoading = false;
          });
          return;
        }

        // 2. Get tasks for these courses
        final taskSnapshot = await FirebaseFirestore.instance
            .collection('tasks')
            .where('courseId', whereIn: courseIds)
            .orderBy('createdAt', descending: true)
            .get();

        final List<Task> tasks = taskSnapshot.docs.map((doc) {
          final data = doc.data();
          return Task(
            id: doc.id,
            courseId: data['courseId'] ?? '',
            title: data['title'] ?? 'Untitled Task',
            description: data['description'] ?? '',
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
            isCompleted: data['isCompleted'] ?? false,
          );
        }).toList();

        // 3. Get student-specific task statuses
        final studentTaskSnapshot = await FirebaseFirestore.instance
            .collection('student_tasks')
            .where('studentId', isEqualTo: studentId)
            .get();

        // Create a map for quick lookup
        final Map<String, StudentTask> studentTaskMap = {};
        for (final doc in studentTaskSnapshot.docs) {
          final data = doc.data();
          final studentTask = StudentTask(
            id: doc.id,
            taskId: data['taskId'] ?? '',
            studentId: data['studentId'] ?? '',
            remarks: data['remarks'] ?? '',
            isCompleted: data['isCompleted'] ?? false,
            completedAt: data['completedAt'] != null
                ? (data['completedAt'] as Timestamp).toDate()
                : null,
          );
          studentTaskMap[studentTask.taskId] = studentTask;
        }

        // 4. Combine tasks with student-specific statuses
        List<TaskWithStatus> tasksWithStatus = tasks.map((task) {
          final hasStudentTask = studentTaskMap.containsKey(task.id);
          final studentTask = hasStudentTask ? studentTaskMap[task.id] : null;

          return TaskWithStatus(
            task: task,
            isCompleted: studentTask?.isCompleted ?? false,
            hasRemarks: studentTask != null && studentTask.remarks.isNotEmpty,
            remarks: studentTask?.remarks ?? '',
            completedAt: studentTask?.completedAt,
          );
        }).toList();

        setState(() {
          _allTasksWithStatus = tasksWithStatus;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading tasks: $e');
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading tasks: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      print('User not authenticated, cannot load tasks');
    }
  }

  List<TaskWithStatus> _getFilteredTasks() {
    // First apply search query
    List<TaskWithStatus> filteredTasks =
        _allTasksWithStatus.where((taskWithStatus) {
      final task = taskWithStatus.task;
      return task.title.toLowerCase().contains(_searchQuery) ||
          task.description.toLowerCase().contains(_searchQuery);
    }).toList();

    // Then apply status filter
    if (_currentFilter == TaskFilter.pending) {
      filteredTasks = filteredTasks
          .where((taskWithStatus) => !taskWithStatus.isCompleted)
          .toList();
    } else if (_currentFilter == TaskFilter.completed) {
      filteredTasks = filteredTasks
          .where((taskWithStatus) => taskWithStatus.isCompleted)
          .toList();
    }

    // Apply course filter if selected
    if (_courseIdFilter != null) {
      filteredTasks = filteredTasks
          .where((taskWithStatus) =>
              taskWithStatus.task.courseId == _courseIdFilter)
          .toList();
    }

    // Sort tasks:
    // 1. Overdue and pending tasks first, sorted by due date (earliest first)
    // 2. Completed tasks next, sorted by due date (latest first)
    filteredTasks.sort((a, b) {
      // If one is completed and the other isn't, completed tasks go after pending tasks
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      // For non-completed tasks, check if one is overdue
      if (!a.isCompleted && !b.isCompleted) {
        bool aIsOverdue =
            TaskUtils.isTaskOverdue(a.task.dueDate, a.isCompleted);
        bool bIsOverdue =
            TaskUtils.isTaskOverdue(b.task.dueDate, b.isCompleted);

        if (aIsOverdue != bIsOverdue) {
          return aIsOverdue ? -1 : 1; // Overdue tasks first
        }
      }

      // If both have the same completion status and overdue status
      // Sort by due date
      if (a.task.dueDate != null && b.task.dueDate != null) {
        // For pending tasks, earlier due dates first
        if (!a.isCompleted) {
          return a.task.dueDate!.compareTo(b.task.dueDate!);
        }
        // For completed tasks, most recent completions first
        else {
          return b.task.dueDate!.compareTo(a.task.dueDate!);
        }
      }
      // If one has a due date and the other doesn't, the one with a due date comes first
      else if (a.task.dueDate != null) {
        return -1;
      } else if (b.task.dueDate != null) {
        return 1;
      }

      // If neither has a due date, sort by creation date (newest first)
      return b.task.createdAt.compareTo(a.task.createdAt);
    });

    return filteredTasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and filter section
                _buildSearchAndFilterSection(),

                // Tasks list or empty state
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _loadStudentTasks();
                      // Add delay to ensure pull-to-refresh animation is visible
                      return await Future.delayed(
                          const Duration(milliseconds: 800));
                    },
                    child: _allTasksWithStatus.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _getFilteredTasks().length,
                            itemBuilder: (context, index) {
                              return _buildTaskCard(
                                  context, _getFilteredTasks()[index]);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.backgroundDark),
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All Tasks',
                  isSelected: _currentFilter == TaskFilter.all,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _currentFilter = TaskFilter.all;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Pending',
                  isSelected: _currentFilter == TaskFilter.pending,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _currentFilter = TaskFilter.pending;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Completed',
                  isSelected: _currentFilter == TaskFilter.completed,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _currentFilter = TaskFilter.completed;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Task count
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_getFilteredTasks().length} tasks found',
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: FilterChip(
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
        ),
        selected: isSelected,
        onSelected: onSelected,
        backgroundColor: AppColors.backgroundLight,
        selectedColor: AppColors.primaryBlueLight,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'No tasks found';
    if (_searchQuery.isNotEmpty) {
      message = 'No tasks match your search';
    } else if (_currentFilter == TaskFilter.pending) {
      message = 'No pending tasks';
    } else if (_currentFilter == TaskFilter.completed) {
      message = 'No completed tasks yet';
    } else if (_allTasksWithStatus.isEmpty) {
      message = 'You don\'t have any tasks assigned yet';
    }

    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height / 4),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _currentFilter == TaskFilter.completed
                    ? Icons.check_circle_outline
                    : Icons.assignment_outlined,
                size: 64,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskWithStatus taskWithStatus) {
    final task = taskWithStatus.task;
    final dueDate = task.dueDate != null
        ? TaskUtils.shortDateFormat.format(task.dueDate!)
        : 'No due date';

    // Check if task is overdue using student's completion status (not the global task status)
    final bool isOverdue =
        TaskUtils.isTaskOverdue(task.dueDate, taskWithStatus.isCompleted);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject indicator (color dot)
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getSubjectColor(task.courseId),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Task title and course
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: taskWithStatus.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: taskWithStatus.isCompleted
                                ? AppColors.textMedium
                                : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getCourseNameFromId(task.courseId),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status icon and remarks indicator
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        taskWithStatus.isCompleted
                            ? Icons.check_circle
                            : isOverdue
                                ? Icons.warning_amber_rounded
                                : Icons.circle_outlined,
                        color: taskWithStatus.isCompleted
                            ? AppColors.success
                            : isOverdue
                                ? AppColors.error
                                : AppColors.primaryBlue,
                      ),
                      if (taskWithStatus.hasRemarks)
                        Icon(
                          Icons.comment,
                          color: AppColors.accentOrange,
                          size: 16,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (task.description.isNotEmpty) ...[
                Text(
                  task.description.length > 100
                      ? '${task.description.substring(0, 100)}...'
                      : task.description,
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Due date
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 16,
                        color: taskWithStatus.isCompleted
                            ? AppColors.textMedium
                            : (isOverdue
                                ? AppColors.error
                                : AppColors.textMedium),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dueDate,
                        style: TextStyle(
                          color: taskWithStatus.isCompleted
                              ? AppColors.textMedium
                              : (isOverdue
                                  ? AppColors.error
                                  : AppColors.textMedium),
                          fontWeight: (!taskWithStatus.isCompleted && isOverdue)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),

                  // Status text
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: taskWithStatus.isCompleted
                          ? AppColors.success.withOpacity(0.2)
                          : isOverdue
                              ? AppColors.error.withOpacity(0.2)
                              : AppColors.primaryBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      taskWithStatus.isCompleted
                          ? 'Completed'
                          : (isOverdue ? 'Overdue' : 'Pending'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: taskWithStatus.isCompleted
                            ? AppColors.success
                            : isOverdue
                                ? AppColors.error
                                : AppColors.primaryBlue,
                      ),
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
    // Handle multi-part subject names (e.g., "bahasa-malaysia-grade1")
    String subject = '';

    if (courseId.contains('mathematics') || courseId.contains('math')) {
      subject = 'mathematics';
    } else if (courseId.contains('science')) {
      subject = 'science';
    } else if (courseId.contains('english')) {
      subject = 'english';
    } else if (courseId.contains('bahasa')) {
      subject = 'bahasa';
    } else if (courseId.contains('chinese')) {
      subject = 'chinese';
    } else {
      // Extract first part if nothing else matches
      final parts = courseId.split('-');
      subject = parts.isNotEmpty ? parts[0] : '';
    }

    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return AppColors.mathSubject;
      case 'science':
        return AppColors.scienceSubject;
      case 'english':
        return AppColors.englishSubject;
      case 'bahasa':
        return AppColors.bahasaSubject;
      case 'chinese':
        return AppColors.chineseSubject;
      default:
        // Use a hash function to get consistent colors for other subjects
        final colors = [
          AppColors.primaryBlue,
          AppColors.accentOrange,
          AppColors.accentTeal,
          AppColors.primaryBlueDark,
          AppColors.secondaryBlue,
        ];

        int hash = 0;
        for (var i = 0; i < courseId.length; i++) {
          hash = (hash + courseId.codeUnitAt(i)) % colors.length;
        }

        return colors[hash];
    }
  }

  String _getCourseNameFromId(String courseId) {
    // Extract subject and grade from courseId (e.g., "bahasa-malaysia-grade1" -> "Bahasa Malaysia Grade 1")
    // We need to handle multi-part subject names like "bahasa-malaysia"

    final parts = courseId.split('-');
    if (parts.isEmpty) return courseId;

    // Check if this follows the pattern we expect
    int gradeIndex = -1;
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].toLowerCase().startsWith('grade')) {
        gradeIndex = i;
        break;
      }
    }

    if (gradeIndex > 0) {
      // Extract subject (may be multiple parts before "grade")
      final subjectParts = parts.sublist(0, gradeIndex);
      final subject = subjectParts.join(' ');

      // Extract grade number (e.g., "grade1" -> "1")
      String grade = parts[gradeIndex];
      if (grade.toLowerCase().startsWith('grade')) {
        grade = grade.substring(5);
      }

      // Capitalize each word in subject
      final capitalizedSubject = subject
          .split(' ')
          .map((word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
          .join(' ');

      return '$capitalizedSubject Grade $grade';
    }

    return courseId; // Fallback
  }
}
