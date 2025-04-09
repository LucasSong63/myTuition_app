import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/student_task.dart';

class StudentTaskDetailsUpdated extends StatefulWidget {
  final StudentTask studentTask;
  final Task? task;
  final VoidCallback onMarkComplete;
  final VoidCallback onMarkIncomplete;
  final Function(String) onUpdateRemarks;
  final String? studentName; // Optional student name

  const StudentTaskDetailsUpdated({
    Key? key,
    required this.studentTask,
    this.task,
    this.studentName,
    required this.onMarkComplete,
    required this.onMarkIncomplete,
    required this.onUpdateRemarks,
  }) : super(key: key);

  @override
  State<StudentTaskDetailsUpdated> createState() =>
      _StudentTaskDetailsUpdatedState();
}

class _StudentTaskDetailsUpdatedState extends State<StudentTaskDetailsUpdated> {
  final _remarksController = TextEditingController();
  bool _isEditingRemarks = false;

  @override
  void initState() {
    super.initState();
    _remarksController.text = widget.studentTask.remarks;
  }

  @override
  void didUpdateWidget(covariant StudentTaskDetailsUpdated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentTask.remarks != widget.studentTask.remarks) {
      _remarksController.text = widget.studentTask.remarks;
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.studentName ?? widget.studentTask.studentId;

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
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Only show student ID if it's different from the display name
                      if (widget.studentName != null)
                        Text(
                          widget.studentTask.studentId,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.studentTask.isCompleted,
                  activeColor: AppColors.success,
                  onChanged: (value) {
                    if (value) {
                      widget.onMarkComplete();
                    } else {
                      widget.onMarkIncomplete();
                    }
                  },
                ),
              ],
            ),

            // Completion status
            Row(
              children: [
                Icon(
                  widget.studentTask.isCompleted
                      ? Icons.check_circle
                      : Icons.pending,
                  color: widget.studentTask.isCompleted
                      ? AppColors.success
                      : AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.studentTask.isCompleted ? 'Completed' : 'Pending',
                  style: TextStyle(
                    color: widget.studentTask.isCompleted
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
                if (widget.studentTask.completedAt != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'on ${DateFormat('dd MMM yyyy').format(widget.studentTask.completedAt!)}',
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
                  icon: Icon(
                    _isEditingRemarks ? Icons.save : Icons.edit,
                    size: 20,
                  ),
                  onPressed: () {
                    if (_isEditingRemarks) {
                      // Save remarks
                      widget.onUpdateRemarks(_remarksController.text);
                    }
                    setState(() {
                      _isEditingRemarks = !_isEditingRemarks;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isEditingRemarks)
              TextField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  hintText: 'Add remarks for this student',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              )
            else
              Text(
                widget.studentTask.remarks.isEmpty
                    ? 'No remarks yet'
                    : widget.studentTask.remarks,
                style: TextStyle(
                  color: widget.studentTask.remarks.isEmpty
                      ? AppColors.textLight
                      : null,
                  fontStyle: widget.studentTask.remarks.isEmpty
                      ? FontStyle.italic
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
