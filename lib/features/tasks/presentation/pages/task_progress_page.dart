import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
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

class _TaskProgressPageState extends State<TaskProgressPage>
    with SingleTickerProviderStateMixin {
  Task? _task;
  List<StudentTask> _studentTasks = [];

  // Student names map
  final Map<String, String> _studentNames = {};
  bool _isLoading = true;
  bool _isReloading = false;

  // Bulk selection
  bool _isSelectionMode = false;
  final Set<String> _selectedStudentIds = {};

  // Animation controller for selection mode
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Filter and sort
  String _filterBy = 'all'; // 'all', 'completed', 'pending'
  String _sortBy = 'name'; // 'name', 'status'

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _loadTaskData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          SnackBar(
            content: Text('Task not found', style: TextStyle(fontSize: 14.sp)),
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
              content: Text('Error loading task details: $e',
                  style: TextStyle(fontSize: 14.sp)),
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
            id: '${widget.taskId}-$studentId',
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

  List<StudentTask> _sortAndFilterTasks(List<StudentTask> tasks) {
    // First filter
    List<StudentTask> filteredTasks = tasks;

    switch (_filterBy) {
      case 'completed':
        filteredTasks = tasks.where((task) => task.isCompleted).toList();
        break;
      case 'pending':
        filteredTasks = tasks.where((task) => !task.isCompleted).toList();
        break;
    }

    // Then sort
    switch (_sortBy) {
      case 'name':
        filteredTasks.sort((a, b) {
          final nameA = _studentNames[a.studentId] ?? a.studentId;
          final nameB = _studentNames[b.studentId] ?? b.studentId;
          return nameA.compareTo(nameB);
        });
        break;
      case 'status':
        filteredTasks.sort((a, b) {
          if (a.isCompleted == b.isCompleted) {
            // If same status, sort by name
            final nameA = _studentNames[a.studentId] ?? a.studentId;
            final nameB = _studentNames[b.studentId] ?? b.studentId;
            return nameA.compareTo(nameB);
          }
          return a.isCompleted ? 1 : -1; // Pending first
        });
        break;
    }

    return filteredTasks;
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedStudentIds.clear();
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

  void _toggleStudentSelection(String studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
      } else {
        _selectedStudentIds.add(studentId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedStudentIds.clear();
      final filteredTasks = _sortAndFilterTasks(_studentTasks);
      _selectedStudentIds.addAll(filteredTasks.map((task) => task.studentId));
    });
  }

  void _bulkMarkComplete() {
    if (_selectedStudentIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark ${_selectedStudentIds.length} Tasks Complete?',
            style: TextStyle(fontSize: 16.sp)),
        content: Text(
          'This will mark the selected students\' tasks as completed.',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processBulkAction(true);
            },
            child: Text('Mark Complete', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  void _bulkMarkIncomplete() {
    if (_selectedStudentIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark ${_selectedStudentIds.length} Tasks Incomplete?',
            style: TextStyle(fontSize: 16.sp)),
        content: Text(
          'This will mark the selected students\' tasks as incomplete.',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processBulkAction(false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: Text('Mark Incomplete', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  void _processBulkAction(bool markAsComplete) {
    setState(() {
      _isReloading = true;
    });

    for (final studentId in _selectedStudentIds) {
      final studentTask = _studentTasks.firstWhere(
        (task) => task.studentId == studentId,
      );

      if (markAsComplete) {
        context.read<TaskBloc>().add(
              MarkTaskAsCompletedEvent(
                taskId: studentTask.taskId,
                studentId: studentTask.studentId,
                remarks: studentTask.remarks,
              ),
            );
      } else {
        context.read<TaskBloc>().add(
              MarkTaskAsIncompleteEvent(
                taskId: studentTask.taskId,
                studentId: studentTask.studentId,
              ),
            );
      }
    }

    _toggleSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Task Progress', style: TextStyle(fontSize: 16.sp)),
        actions: [
          if (!_isSelectionMode) ...[
            PopupMenuButton<String>(
              icon: Icon(Icons.filter_list, size: 6.w),
              onSelected: (value) {
                setState(() {
                  if (value.startsWith('filter_')) {
                    _filterBy = value.substring(7);
                  } else if (value.startsWith('sort_')) {
                    _sortBy = value.substring(5);
                  }
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'header_filter',
                  enabled: false,
                  child: Text(
                    'Filter By',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuItem(
                  value: 'filter_all',
                  child: Row(
                    children: [
                      const Icon(Icons.all_inclusive),
                      SizedBox(width: 2.w),
                      const Text('All Students'),
                      if (_filterBy == 'all') ...[
                        const Spacer(),
                        const Icon(Icons.check, color: AppColors.primaryBlue),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'filter_completed',
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      SizedBox(width: 2.w),
                      const Text('Completed'),
                      if (_filterBy == 'completed') ...[
                        const Spacer(),
                        const Icon(Icons.check, color: AppColors.primaryBlue),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'filter_pending',
                  child: Row(
                    children: [
                      const Icon(Icons.pending, color: AppColors.warning),
                      SizedBox(width: 2.w),
                      const Text('Pending'),
                      if (_filterBy == 'pending') ...[
                        const Spacer(),
                        const Icon(Icons.check, color: AppColors.primaryBlue),
                      ],
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'header_sort',
                  enabled: false,
                  child: Text(
                    'Sort By',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuItem(
                  value: 'sort_name',
                  child: Row(
                    children: [
                      const Icon(Icons.sort_by_alpha),
                      SizedBox(width: 2.w),
                      const Text('Name'),
                      if (_sortBy == 'name') ...[
                        const Spacer(),
                        const Icon(Icons.check, color: AppColors.primaryBlue),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'sort_status',
                  child: Row(
                    children: [
                      const Icon(Icons.flag),
                      SizedBox(width: 2.w),
                      const Text('Status'),
                      if (_sortBy == 'status') ...[
                        const Spacer(),
                        const Icon(Icons.check, color: AppColors.primaryBlue),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.checklist, size: 6.w),
              onPressed: _toggleSelectionMode,
              tooltip: 'Bulk Actions',
            ),
          ] else ...[
            TextButton(
              onPressed: _selectAll,
              child: Text(
                'Select All',
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 6.w),
              onPressed: _toggleSelectionMode,
            ),
          ],
        ],
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
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
                  content:
                      Text(state.message, style: TextStyle(fontSize: 14.sp)),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _task == null
                ? _buildErrorState()
                : _buildContent(),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return _isSelectionMode
              ? FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildBulkActionsBar(),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 16.w,
            color: AppColors.error,
          ),
          SizedBox(height: 2.h),
          Text(
            'Task not found',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: _loadTaskData,
            child: Text('Retry', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final filteredTasks = _sortAndFilterTasks(_studentTasks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task details card
        _buildTaskDetailsCard(),

        // Progress summary
        _buildProgressSummary(),

        // Students list
        Expanded(
          child: filteredTasks.isEmpty
              ? _buildEmptyState()
              : _buildStudentList(filteredTasks),
        ),
      ],
    );
  }

  Widget _buildTaskDetailsCard() {
    final isOverdue = TaskUtils.isTaskOverdue(_task!.dueDate, false);

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.8),
            AppColors.primaryBlueDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _task!.title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_task!.description.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Text(
              _task!.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13.sp,
              ),
            ),
          ],
          SizedBox(height: 2.h),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 4.w,
                color: Colors.white.withOpacity(0.9),
              ),
              SizedBox(width: 2.w),
              Text(
                _task!.dueDate != null
                    ? 'Due: ${DateFormat('MMM d, yyyy').format(_task!.dueDate!)}'
                    : 'No due date',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12.sp,
                ),
              ),
              if (isOverdue) ...[
                SizedBox(width: 3.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Text(
                    'Overdue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary() {
    final completedCount =
        _studentTasks.where((task) => task.isCompleted).length;
    final totalCount = _studentTasks.length;
    final percentage = totalCount > 0 ? (completedCount / totalCount) * 100 : 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Student Progress',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$completedCount / $totalCount completed',
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(2.w),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 2.h,
              backgroundColor: AppColors.backgroundDark,
              color: percentage == 100
                  ? AppColors.success
                  : percentage >= 70
                      ? AppColors.primaryBlue
                      : AppColors.warning,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '${percentage.toStringAsFixed(0)}% Complete',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 16.w,
            color: AppColors.textLight,
          ),
          SizedBox(height: 2.h),
          Text(
            _filterBy == 'all'
                ? 'No student progress available'
                : 'No ${_filterBy} tasks',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            _filterBy == 'all'
                ? 'Students need to be enrolled in this course'
                : 'Try changing the filter to see more tasks',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMedium,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<StudentTask> filteredTasks) {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final studentTask = filteredTasks[index];
        return _buildStudentTaskCard(studentTask);
      },
    );
  }

  Widget _buildStudentTaskCard(StudentTask studentTask) {
    // Get student name from our map, or use student ID if name not found
    final studentName = _studentNames[studentTask.studentId] ??
        'Student ${studentTask.studentId}';

    final isSelected = _selectedStudentIds.contains(studentTask.studentId);

    return Card(
      margin: EdgeInsets.only(bottom: 3.w),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
        side: isSelected
            ? BorderSide(color: AppColors.primaryBlue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(3.w),
        onTap: _isSelectionMode
            ? () => _toggleStudentSelection(studentTask.studentId)
            : null,
        onLongPress: !_isSelectionMode
            ? () {
                _toggleSelectionMode();
                _toggleStudentSelection(studentTask.studentId);
              }
            : null,
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student name and toggle
              Row(
                children: [
                  if (_isSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) =>
                          _toggleStudentSelection(studentTask.studentId),
                      activeColor: AppColors.primaryBlue,
                    ),
                    SizedBox(width: 2.w),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          studentTask.studentId,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isSelectionMode)
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

              SizedBox(height: 2.h),

              // Completion status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: studentTask.isCompleted
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      studentTask.isCompleted
                          ? Icons.check_circle
                          : Icons.pending,
                      color: studentTask.isCompleted
                          ? AppColors.success
                          : AppColors.warning,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      studentTask.isCompleted ? 'Completed' : 'Pending',
                      style: TextStyle(
                        color: studentTask.isCompleted
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                    if (studentTask.completedAt != null) ...[
                      SizedBox(width: 2.w),
                      Text(
                        '• ${DateFormat('MMM d, h:mm a').format(studentTask.completedAt!)}',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Remarks section
              SizedBox(height: 2.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(2.w),
                  border: Border.all(
                    color: AppColors.backgroundDark.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tutor Remarks',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                        if (!_isSelectionMode)
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: 4.w,
                              color: AppColors.primaryBlue,
                            ),
                            onPressed: () => _showRemarksDialog(studentTask),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      studentTask.remarks.isEmpty
                          ? 'No remarks yet. Tap edit to add feedback.'
                          : studentTask.remarks,
                      style: TextStyle(
                        color: studentTask.remarks.isEmpty
                            ? AppColors.textLight
                            : AppColors.textDark,
                        fontStyle: studentTask.remarks.isEmpty
                            ? FontStyle.italic
                            : null,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulkActionsBar() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Text(
              '${_selectedStudentIds.length} selected',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed:
                  _selectedStudentIds.isEmpty ? null : _bulkMarkIncomplete,
              icon: Icon(Icons.unpublished, size: 4.w),
              label: Text('Mark Incomplete', style: TextStyle(fontSize: 12.sp)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: BorderSide(color: AppColors.warning),
              ),
            ),
            SizedBox(width: 2.w),
            ElevatedButton.icon(
              onPressed: _selectedStudentIds.isEmpty ? null : _bulkMarkComplete,
              icon: Icon(Icons.check_circle, size: 4.w),
              label: Text('Mark Complete', style: TextStyle(fontSize: 12.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemarksDialog(StudentTask studentTask) {
    final remarksController = TextEditingController(text: studentTask.remarks);
    final studentName =
        _studentNames[studentTask.studentId] ?? studentTask.studentId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remarks for $studentName',
          style: TextStyle(fontSize: 16.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add feedback that will be visible to the student',
              style: TextStyle(
                color: AppColors.textMedium,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: remarksController,
              decoration: InputDecoration(
                hintText: 'Enter your feedback here...',
                hintStyle: TextStyle(fontSize: 14.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
                contentPadding: EdgeInsets.all(3.w),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 14.sp),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateRemarks(studentTask, remarksController.text);
            },
            child: Text('Save', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
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
