import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/core/utils/task_utils.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../widgets/task_bottom_sheet.dart';

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
  String _sortBy = 'date'; // 'date', 'title', 'due'
  String _filterBy = 'all'; // 'all', 'overdue', 'upcoming'

  @override
  void initState() {
    super.initState();
    courseId = widget.courseId;
    courseName = widget.courseName;

    // Use a small delay to ensure the BLoC is properly initialized before loading tasks
    Future.microtask(() {
      if (mounted) {
        context.read<TaskBloc>().add(
              LoadTasksByCourseEvent(courseId: courseId),
            );
      }
    });
  }

  List<Task> _sortAndFilterTasks(List<Task> tasks) {
    // First filter
    List<Task> filteredTasks = tasks;
    final now = DateTime.now();
    
    switch (_filterBy) {
      case 'overdue':
        filteredTasks = tasks.where((task) => 
          task.dueDate != null && 
          task.dueDate!.isBefore(now) && 
          !task.isCompleted
        ).toList();
        break;
      case 'upcoming':
        filteredTasks = tasks.where((task) => 
          task.dueDate != null && 
          task.dueDate!.isAfter(now)
        ).toList();
        break;
    }

    // Then sort
    switch (_sortBy) {
      case 'title':
        filteredTasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'due':
        filteredTasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      default: // 'date' - by creation date
        filteredTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filteredTasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Management',
              style: TextStyle(fontSize: 16.sp),
            ),
            Text(
              courseName,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.normal,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, size: 6.w),
            onSelected: (value) {
              setState(() {
                if (value.startsWith('sort_')) {
                  _sortBy = value.substring(5);
                } else if (value.startsWith('filter_')) {
                  _filterBy = value.substring(7);
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'header_sort',
                enabled: false,
                child: Text(
                  'Sort By',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuItem(
                value: 'sort_date',
                child: Row(
                  children: [
                    Icon(Icons.date_range, size: 5.w),
                    SizedBox(width: 2.w),
                    const Text('Creation Date'),
                    if (_sortBy == 'date') ...[
                      const Spacer(),
                      Icon(Icons.check, size: 5.w, color: AppColors.primaryBlue),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sort_title',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 5.w),
                    SizedBox(width: 2.w),
                    const Text('Title'),
                    if (_sortBy == 'title') ...[
                      const Spacer(),
                      Icon(Icons.check, size: 5.w, color: AppColors.primaryBlue),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sort_due',
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 5.w),
                    SizedBox(width: 2.w),
                    const Text('Due Date'),
                    if (_sortBy == 'due') ...[
                      const Spacer(),
                      Icon(Icons.check, size: 5.w, color: AppColors.primaryBlue),
                    ],
                  ],
                ),
              ),
              const PopupMenuDivider(),
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
                    Icon(Icons.all_inclusive, size: 5.w),
                    SizedBox(width: 2.w),
                    const Text('All Tasks'),
                    if (_filterBy == 'all') ...[
                      const Spacer(),
                      Icon(Icons.check, size: 5.w, color: AppColors.primaryBlue),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'filter_overdue',
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 5.w, color: AppColors.error),
                    SizedBox(width: 2.w),
                    const Text('Overdue'),
                    if (_filterBy == 'overdue') ...[
                      const Spacer(),
                      Icon(Icons.check, size: 5.w, color: AppColors.primaryBlue),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'filter_upcoming',
                child: Row(
                  children: [
                    Icon(Icons.upcoming, size: 5.w, color: AppColors.success),
                    SizedBox(width: 2.w),
                    const Text('Upcoming'),
                    if (_filterBy == 'upcoming') ...[
                      const Spacer(),
                      Icon(Icons.check, size: 5.w, color: AppColors.primaryBlue),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
                backgroundColor: AppColors.success,
              ),
            );
          }
          if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: TextStyle(fontSize: 14.sp)),
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
            final tasks = _sortAndFilterTasks(state.tasks);
            
            return Column(
              children: [
                // Header section with statistics
                _buildStatisticsSection(state.tasks),
                
                // Task list
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
                Icon(
                  Icons.error_outline,
                  size: 12.w,
                  color: AppColors.error,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Failed to load tasks',
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(height: 1.h),
                ElevatedButton(
                  onPressed: () {
                    context.read<TaskBloc>().add(
                          LoadTasksByCourseEvent(courseId: courseId),
                        );
                  },
                  child: Text('Retry', style: TextStyle(fontSize: 14.sp)),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskBottomSheet(context),
        icon: Icon(Icons.add, size: 6.w),
        label: Text('Add Task', style: TextStyle(fontSize: 14.sp)),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildStatisticsSection(List<Task> allTasks) {
    final overdueCount = allTasks.where((task) => 
      TaskUtils.isTaskOverdue(task.dueDate, task.isCompleted)
    ).length;
    
    final upcomingCount = allTasks.where((task) => 
      task.dueDate != null && 
      task.dueDate!.isAfter(DateTime.now())
    ).length;

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            'Total Tasks',
            '${allTasks.length}',
            Icons.assignment,
            Colors.white,
          ),
          _buildStatCard(
            'Overdue',
            '$overdueCount',
            Icons.warning,
            overdueCount > 0 ? Colors.orange : Colors.white,
          ),
          _buildStatCard(
            'Upcoming',
            '$upcomingCount',
            Icons.upcoming,
            Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 6.w),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: color.withOpacity(0.9),
          ),
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
            Icons.assignment_outlined,
            size: 16.w,
            color: AppColors.textLight,
          ),
          SizedBox(height: 2.h),
          Text(
            _filterBy == 'all' 
              ? 'No tasks available'
              : 'No ${_filterBy} tasks',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _filterBy == 'all'
              ? 'Create your first task for students'
              : 'Try changing the filter to see more tasks',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMedium,
              fontSize: 14.sp,
            ),
          ),
          if (_filterBy == 'all') ...[
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () => _showTaskBottomSheet(context),
              icon: Icon(Icons.add, size: 5.w),
              label: Text('Create Task', style: TextStyle(fontSize: 14.sp)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.w),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, List<Task> tasks) {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(context, task);
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final bool isOverdue = TaskUtils.isTaskOverdue(task.dueDate, task.isCompleted);
    final bool hasNoDueDate = task.dueDate == null;
    
    return Card(
      margin: EdgeInsets.only(bottom: 3.w),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(3.w),
        onTap: () {
          context.push('/tutor/tasks/${task.id}');
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3.w),
            border: Border(
              left: BorderSide(
                color: isOverdue 
                  ? AppColors.error 
                  : hasNoDueDate 
                    ? AppColors.textLight
                    : AppColors.primaryBlue,
                width: 1.w,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and actions row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (task.description.isNotEmpty) ...[
                            SizedBox(height: 1.h),
                            Text(
                              task.description,
                              style: TextStyle(
                                color: AppColors.textMedium,
                                fontSize: 13.sp,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Action buttons
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 5.w),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showTaskBottomSheet(context, task: task);
                            break;
                          case 'delete':
                            _confirmDeleteTask(context, task);
                            break;
                          case 'view_progress':
                            context.push('/tutor/tasks/${task.id}');
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view_progress',
                          child: Row(
                            children: [
                              Icon(Icons.people, size: 5.w),
                              SizedBox(width: 3.w),
                              Text('View Progress', style: TextStyle(fontSize: 14.sp)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 5.w, color: AppColors.primaryBlue),
                              SizedBox(width: 3.w),
                              Text('Edit Task', style: TextStyle(fontSize: 14.sp)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 5.w, color: AppColors.error),
                              SizedBox(width: 3.w),
                              Text('Delete', 
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                SizedBox(height: 2.h),
                
                // Date and status information
                Row(
                  children: [
                    // Due date chip
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: isOverdue
                          ? AppColors.error.withOpacity(0.1)
                          : hasNoDueDate
                            ? AppColors.textLight.withOpacity(0.1)
                            : AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOverdue ? Icons.warning : Icons.calendar_today,
                            size: 4.w,
                            color: isOverdue
                              ? AppColors.error
                              : hasNoDueDate
                                ? AppColors.textMedium
                                : AppColors.primaryBlue,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            task.dueDate != null
                              ? DateFormat('MMM d, yyyy').format(task.dueDate!)
                              : 'No due date',
                            style: TextStyle(
                              color: isOverdue
                                ? AppColors.error
                                : hasNoDueDate
                                  ? AppColors.textMedium
                                  : AppColors.primaryBlue,
                              fontWeight: FontWeight.w500,
                              fontSize: 12.sp,
                            ),
                          ),
                          if (isOverdue) ...[
                            SizedBox(width: 2.w),
                            Text(
                              'Overdue',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // View progress button
                    TextButton.icon(
                      onPressed: () {
                        context.push('/tutor/tasks/${task.id}');
                      },
                      icon: Icon(Icons.people_outline, size: 4.w),
                      label: Text('View Progress', style: TextStyle(fontSize: 12.sp)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                
                // Created date at bottom
                SizedBox(height: 1.h),
                Text(
                  'Created ${DateFormat('MMM d, yyyy').format(task.createdAt)}',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskBottomSheet(BuildContext context, {Task? task}) {
    TaskBottomSheet.show(
      context: context,
      courseId: courseId,
      courseName: courseName,
      existingTask: task,
    );
  }

  void _confirmDeleteTask(BuildContext context, Task task) {
    // Store a reference to the TaskBloc before showing the dialog
    final taskBloc = context.read<TaskBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Task', style: TextStyle(fontSize: 16.sp)),
        content: Text(
          'Are you sure you want to delete "${task.title}"?\n\nThis action cannot be undone and all student progress will be lost.',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleting task...', style: TextStyle(fontSize: 14.sp)),
                  duration: const Duration(seconds: 1),
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
            child: Text('Delete', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }
}