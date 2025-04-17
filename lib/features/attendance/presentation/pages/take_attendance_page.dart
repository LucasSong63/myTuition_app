import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../../domain/entities/attendance.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class TakeAttendancePage extends StatefulWidget {
  final String courseId;
  final String courseName;

  const TakeAttendancePage({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  State<TakeAttendancePage> createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  late DateTime _selectedDate;
  Map<String, AttendanceStatus> _studentAttendances = {};
  Map<String, String> _studentRemarks = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    // Load enrolled students and any existing attendance for today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<AttendanceBloc>().add(
          LoadEnrolledStudentsEvent(courseId: widget.courseId),
        );

    context.read<AttendanceBloc>().add(
          LoadAttendanceByDateEvent(
            courseId: widget.courseId,
            date: _selectedDate,
          ),
        );
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });

      // Reload attendance for the selected date
      context.read<AttendanceBloc>().add(
            LoadAttendanceByDateEvent(
              courseId: widget.courseId,
              date: _selectedDate,
            ),
          );
    }
  }

  void _submitAttendance() {
    if (_studentAttendances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No attendance data to submit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Filter out empty remarks
    final Map<String, String> nonEmptyRemarks = {};
    _studentRemarks.forEach((key, value) {
      if (value.trim().isNotEmpty) {
        nonEmptyRemarks[key] = value;
      }
    });

    // Submit attendance data
    context.read<AttendanceBloc>().add(
          RecordBulkAttendanceEvent(
            courseId: widget.courseId,
            date: _selectedDate,
            studentAttendances: _studentAttendances,
            remarks: nonEmptyRemarks.isNotEmpty ? nonEmptyRemarks : null,
          ),
        );
  }

  // Add this method to mark all students with the same status
  void _markAllStudents(AttendanceStatus status) {
    final state = context.read<AttendanceBloc>().state;

    if (state is EnrolledStudentsLoaded) {
      setState(() {
        for (var student in state.students) {
          final studentId = student['studentId'] as String;
          _studentAttendances[studentId] = status;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance: ${widget.courseName}'),
      ),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
            setState(() {
              _isSubmitting = false;
            });
          }

          if (state is AttendanceRecordSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            setState(() {
              _isSubmitting = false;
            });
          }

          // Handle existing attendance data
          if (state is AttendanceByDateLoaded) {
            if (state.attendanceRecords.isNotEmpty) {
              // Update the student attendances map with existing data
              final existingAttendances = <String, AttendanceStatus>{};
              final existingRemarks = <String, String>{};

              for (var record in state.attendanceRecords) {
                existingAttendances[record.studentId] = record.status;
                if (record.remarks != null && record.remarks!.isNotEmpty) {
                  existingRemarks[record.studentId] = record.remarks!;
                }
              }

              setState(() {
                _studentAttendances = existingAttendances;
                _studentRemarks = existingRemarks;
              });
            }
          }
        },
        builder: (context, state) {
          // Show loading overlay when submitting
          if (_isSubmitting) {
            return Stack(
              children: [
                _buildContent(state),
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Saving attendance records...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return _buildContent(state);
        },
      ),
    );
  }

  Widget _buildContent(AttendanceState state) {
    return Column(
      children: [
        // Date selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                'Date: ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _selectDate(context),
              ),
            ),
          ),
        ),

        // Bulk actions section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bulk Actions:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      label: const Text('All Present'),
                      avatar: Icon(Icons.check, color: AppColors.success),
                      backgroundColor: AppColors.success.withOpacity(0.1),
                      onPressed: () =>
                          _markAllStudents(AttendanceStatus.present),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('All Absent'),
                      avatar: Icon(Icons.close, color: AppColors.error),
                      backgroundColor: AppColors.error.withOpacity(0.1),
                      onPressed: () =>
                          _markAllStudents(AttendanceStatus.absent),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('All Late'),
                      avatar: Icon(Icons.watch_later, color: AppColors.warning),
                      backgroundColor: AppColors.warning.withOpacity(0.1),
                      onPressed: () => _markAllStudents(AttendanceStatus.late),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('All Excused'),
                      avatar: Icon(Icons.medical_services,
                          color: AppColors.accentTeal),
                      backgroundColor: AppColors.accentTeal.withOpacity(0.1),
                      onPressed: () =>
                          _markAllStudents(AttendanceStatus.excused),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Students list with attendance options
        if (state is AttendanceLoading && _studentAttendances.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading student data...'),
                ],
              ),
            ),
          )
        else if (state is EnrolledStudentsLoaded)
          Expanded(
            child: _buildStudentsList(state.students),
          )
        else if (state is AttendanceByDateLoaded &&
            state is! EnrolledStudentsLoaded)
          const Expanded(
            child: Center(child: Text('Waiting for student data...')),
          )
        else
          const Expanded(
            child: Center(child: Text('No data available')),
          ),

        // Submit button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isSubmitting || _studentAttendances.isEmpty
                  ? null
                  : _submitAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Text(
                _studentAttendances.isEmpty
                    ? 'No Students to Record'
                    : 'Save Attendance',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsList(List<Map<String, dynamic>> students) {
    if (students.isEmpty) {
      return const Center(
        child: Text('No students enrolled in this course'),
      );
    }

    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final studentId = student['studentId'] as String;
        final attendance =
            _studentAttendances[studentId] ?? AttendanceStatus.absent;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              child: Text(student['name'].toString().isNotEmpty
                  ? student['name'].toString()[0].toUpperCase()
                  : '?'),
            ),
            title: Text(
              student['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(studentId),
            trailing: _buildAttendanceStatusChip(attendance),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildAttendanceOptions(studentId),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Remarks (optional)',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _studentRemarks[studentId] ?? '',
                      onChanged: (value) {
                        setState(() {
                          _studentRemarks[studentId] = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceStatusChip(AttendanceStatus status) {
    Color chipColor;
    String label;

    switch (status) {
      case AttendanceStatus.present:
        chipColor = AppColors.success;
        label = 'Present';
        break;
      case AttendanceStatus.absent:
        chipColor = AppColors.error;
        label = 'Absent';
        break;
      case AttendanceStatus.late:
        chipColor = AppColors.warning;
        label = 'Late';
        break;
      case AttendanceStatus.excused:
        chipColor = AppColors.accentTeal;
        label = 'Excused';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAttendanceOptions(String studentId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAttendanceOption(
          studentId,
          AttendanceStatus.present,
          'Present',
          AppColors.success,
        ),
        _buildAttendanceOption(
          studentId,
          AttendanceStatus.absent,
          'Absent',
          AppColors.error,
        ),
        _buildAttendanceOption(
          studentId,
          AttendanceStatus.late,
          'Late',
          AppColors.warning,
        ),
        _buildAttendanceOption(
          studentId,
          AttendanceStatus.excused,
          'Excused',
          AppColors.accentTeal,
        ),
      ],
    );
  }

  Widget _buildAttendanceOption(
    String studentId,
    AttendanceStatus status,
    String label,
    Color color,
  ) {
    final isSelected = _studentAttendances[studentId] == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _studentAttendances[studentId] = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
