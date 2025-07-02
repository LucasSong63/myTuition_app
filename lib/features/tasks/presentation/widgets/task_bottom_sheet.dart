import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/tasks/domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';

class TaskBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required String courseId,
    required String courseName,
    Task? existingTask,
  }) async {
    // Get the existing bloc from the parent context
    final TaskBloc parentBloc = context.read<TaskBloc>();

    // Define the page content builder function
    WoltModalSheetPage pageBuilder(BuildContext context) {
      return WoltModalSheetPage(
        hasSabGradient: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        topBarTitle: Text(
          existingTask == null ? 'Add New Task' : 'Edit Task',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        isTopBarLayerAlwaysVisible: true,
        trailingNavBarWidget: IconButton(
          padding: EdgeInsets.all(4.w),
          icon: Icon(Icons.close, size: 6.w),
          onPressed: () => Navigator.of(context).pop(),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600, // Limit width on larger screens
                ),
                // Use BlocProvider.value to share the existing bloc
                child: BlocProvider.value(
                  value: parentBloc,
                  child: _TaskContent(
                    courseId: courseId,
                    courseName: courseName,
                    existingTask: existingTask,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    await WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [pageBuilder(context)],
      modalTypeBuilder: (context) => WoltModalType.bottomSheet(),
      onModalDismissedWithBarrierTap: () => Navigator.of(context).pop(),
    );
  }
}

class _TaskContent extends StatefulWidget {
  final String courseId;
  final String courseName;
  final Task? existingTask;

  const _TaskContent({
    required this.courseId,
    required this.courseName,
    this.existingTask,
  });

  @override
  State<_TaskContent> createState() => _TaskContentState();
}

class _TaskContentState extends State<_TaskContent> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      _titleController.text = widget.existingTask!.title;
      _descriptionController.text = widget.existingTask!.description;
      _selectedDueDate = widget.existingTask!.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (widget.existingTask == null) {
        // Create new task
        context.read<TaskBloc>().add(
              CreateTaskEvent(
                courseId: widget.courseId,
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                dueDate: _selectedDueDate,
              ),
            );
      } else {
        // Update existing task
        final updatedTask = Task(
          id: widget.existingTask!.id,
          courseId: widget.existingTask!.courseId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          createdAt: widget.existingTask!.createdAt,
          dueDate: _selectedDueDate,
          isCompleted: widget.existingTask!.isCompleted,
        );
        
        context.read<TaskBloc>().add(UpdateTaskEvent(task: updatedTask));
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskActionSuccess) {
          Navigator.pop(context); // Close sheet on success
        } else if (state is TaskError) {
          // Show error but don't close sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: TextStyle(fontSize: 14.sp),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Course info header
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.w),
                ),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.assignment,
                        color: AppColors.primaryBlue,
                        size: 7.w,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.courseName,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.existingTask == null
                                  ? 'Create a new task for students'
                                  : 'Update task details',
                              style: TextStyle(
                                color: AppColors.textMedium,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 6.w),

              // Task title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Title',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2.w),
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: 'Enter task title',
                      hintStyle: TextStyle(fontSize: 14.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3.w),
                      ),
                      prefixIcon: Icon(Icons.title, size: 5.w),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 3.w,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              SizedBox(height: 4.w),

              // Task description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2.w),
                  TextFormField(
                    controller: _descriptionController,
                    style: TextStyle(fontSize: 14.sp),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter task description (optional)',
                      hintStyle: TextStyle(fontSize: 14.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3.w),
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 8.w),
                        child: Icon(Icons.description, size: 5.w),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 3.w,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.w),

              // Due date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due Date (Optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2.w),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.backgroundDark),
                        borderRadius: BorderRadius.circular(3.w),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: AppColors.primaryBlue,
                            size: 5.w,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              _selectedDueDate != null
                                  ? DateFormat('EEEE, MMM d, yyyy').format(_selectedDueDate!)
                                  : 'Select a due date',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: _selectedDueDate != null
                                    ? AppColors.textDark
                                    : AppColors.textLight,
                              ),
                            ),
                          ),
                          if (_selectedDueDate != null)
                            IconButton(
                              icon: Icon(Icons.clear, size: 5.w),
                              onPressed: () {
                                setState(() {
                                  _selectedDueDate = null;
                                });
                              },
                              color: AppColors.textMedium,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8.w),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 3.5.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2.w),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: BlocBuilder<TaskBloc, TaskState>(
                      builder: (context, state) {
                        final isLoading = state is TaskLoading;

                        return ElevatedButton(
                          onPressed: isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 3.5.w),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2.w),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 5.w,
                                  height: 5.w,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.existingTask == null
                                      ? 'Create Task'
                                      : 'Update Task',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        );
                      },
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
}