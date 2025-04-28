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
  List<Task> _allTasks = [];
  bool _isLoading = false;

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

  void _loadStudentTasks() {
    setState(() {
      _isLoading = true;
    });

    // Get the student ID from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      // In your Firestore structure, students are stored in the 'students' array in classes
      // The format used there could be either user.studentId or user.id
      // Let's try to get the correct student ID from the user object
      String studentId = '';

      // If your User entity has a studentId field that matches what's in Firestore
      if (authState.user.studentId != null &&
          authState.user.studentId!.isNotEmpty) {
        studentId = authState.user.studentId!;
      } else {
        // Otherwise, fall back to the user's ID
        studentId = authState.user.id;
      }

      print('Loading tasks for student ID: $studentId');

      // Call the task bloc to load tasks for this student
      context.read<TaskBloc>().add(
            LoadTasksForStudentEvent(studentId: studentId),
          );
    } else {
      setState(() {
        _isLoading = false;
      });
      print('User not authenticated, cannot load tasks');
    }
  }

  List<Task> _getFilteredTasks() {
    // First apply search query
    List<Task> filteredTasks = _allTasks.where((task) {
      return task.title.toLowerCase().contains(_searchQuery) ||
          task.description.toLowerCase().contains(_searchQuery);
    }).toList();

    // Then apply status filter
    if (_currentFilter == TaskFilter.pending) {
      filteredTasks = filteredTasks.where((task) => !task.isCompleted).toList();
    } else if (_currentFilter == TaskFilter.completed) {
      filteredTasks = filteredTasks.where((task) => task.isCompleted).toList();
    }

    // Apply course filter if selected
    if (_courseIdFilter != null) {
      filteredTasks = filteredTasks
          .where((task) => task.courseId == _courseIdFilter)
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

      // If both are pending/completed, sort by due date
      if (a.dueDate != null && b.dueDate != null) {
        // For pending tasks, earlier due dates first
        if (!a.isCompleted) {
          return a.dueDate!.compareTo(b.dueDate!);
        }
        // For completed tasks, most recent completions first
        else {
          return b.dueDate!.compareTo(a.dueDate!);
        }
      }
      // If one has a due date and the other doesn't, the one with a due date comes first
      else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }

      // If neither has a due date, sort by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });

    return filteredTasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TasksLoaded) {
            print('Received ${state.tasks.length} tasks from TaskBloc');
            setState(() {
              _allTasks = state.tasks;
              _isLoading = false;
            });
          } else if (state is TaskError) {
            print('TaskBloc error: ${state.message}');
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is TaskLoading) {
            print('TaskBloc is loading');
          }
        },
        builder: (context, state) {
          // Show loading indicator initially
          if (_isLoading || (state is TaskLoading && _allTasks.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredTasks = _getFilteredTasks();
          print('Displaying ${filteredTasks.length} filtered tasks');

          return Column(
            children: [
              // Search and filter section
              _buildSearchAndFilterSection(),

              // Tasks list or empty state
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _loadStudentTasks();
                    // Add delay to ensure pull-to-refresh animation is visible
                    return await Future.delayed(
                        const Duration(milliseconds: 800));
                  },
                  child: filteredTasks.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            return _buildTaskCard(
                                context, filteredTasks[index]);
                          },
                        ),
                ),
              ),
            ],
          );
        },
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
    return FilterChip(
      label: Text(label),
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
    } else if (_allTasks.isEmpty) {
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

  Widget _buildTaskCard(BuildContext context, Task task) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final dueDate =
        task.dueDate != null ? dateFormat.format(task.dueDate!) : 'No due date';

    // Check if due date is in the past
    final bool isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    // This would normally need to query the student_tasks collection
    // to check if there are remarks for this student's task
    // For now we'll need to simulate this based on task data
    // We'll make this deterministic based on task ID characteristics
    final bool hasRemarks = task.title.contains("2") ||
        (task.description.isNotEmpty && task.description.length > 5);

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
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
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
                        task.isCompleted
                            ? Icons.check_circle
                            : isOverdue
                                ? Icons.warning_amber_rounded
                                : Icons.circle_outlined,
                        color: task.isCompleted
                            ? AppColors.success
                            : isOverdue
                                ? AppColors.error
                                : AppColors.primaryBlue,
                      ),
                      if (hasRemarks)
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? AppColors.success.withOpacity(0.2)
                          : isOverdue
                              ? AppColors.error.withOpacity(0.2)
                              : AppColors.primaryBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.isCompleted
                          ? 'Completed'
                          : isOverdue
                              ? 'Overdue'
                              : 'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: task.isCompleted
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
