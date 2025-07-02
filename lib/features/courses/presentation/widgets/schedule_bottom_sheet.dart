import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_bloc.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_event.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_state.dart';
import '../../domain/entities/schedule.dart';

class ScheduleBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required String courseId,
    Schedule? existingSchedule,
  }) async {
    // Get the existing bloc from the parent context
    final CourseBloc parentBloc = context.read<CourseBloc>();

    // Define the page content builder function
    WoltModalSheetPage pageBuilder(BuildContext context) {
      return WoltModalSheetPage(
        hasSabGradient: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        topBarTitle: Text(
          existingSchedule == null
              ? 'Add Class Schedule'
              : 'Edit Class Schedule',
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
                  child: _ScheduleContent(
                    courseId: courseId,
                    existingSchedule: existingSchedule,
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

class _ScheduleContent extends StatefulWidget {
  final Schedule? existingSchedule;
  final String courseId;

  const _ScheduleContent({
    this.existingSchedule,
    required this.courseId,
  });

  @override
  State<_ScheduleContent> createState() => _ScheduleContentState();
}

class _ScheduleContentState extends State<_ScheduleContent> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();

  String _selectedDay = 'Monday';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingSchedule != null) {
      _selectedDay = widget.existingSchedule!.day;
      _startTime = TimeOfDay.fromDateTime(widget.existingSchedule!.startTime);
      _endTime = TimeOfDay.fromDateTime(widget.existingSchedule!.endTime);
      _locationController.text = widget.existingSchedule!.location;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
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

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // If end time is before start time, adjust it
          if (_timeToMinutes(_endTime) < _timeToMinutes(_startTime)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm(); // format like 10:00 AM
    return format.format(dt);
  }

  void _saveSchedule() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final startDateTime = DateTime(
          now.year, now.month, now.day, _startTime.hour, _startTime.minute);
      final endDateTime = DateTime(
          now.year, now.month, now.day, _endTime.hour, _endTime.minute);

      if (widget.existingSchedule == null) {
        // Adding new schedule
        // Generate unique ID using timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final scheduleId = '${widget.courseId}-regular-$timestamp';
        
        final schedule = Schedule(
          id: scheduleId,
          courseId: widget.courseId,
          day: _selectedDay,
          startTime: startDateTime,
          endTime: endDateTime,
          location: _locationController.text,
          subject: 'Subject',
          // These will be populated by the backend
          grade: 0,
          type: ScheduleType.regular,
          isActive: true,
          createdAt: DateTime.now(),
        );

        context.read<CourseBloc>().add(
            AddScheduleEvent(courseId: widget.courseId, schedule: schedule));
      } else {
        // Updating existing schedule
        final updatedSchedule = Schedule(
          id: widget.existingSchedule!.id,
          courseId: widget.courseId,
          day: _selectedDay,
          startTime: startDateTime,
          endTime: endDateTime,
          location: _locationController.text,
          subject: widget.existingSchedule!.subject,
          grade: widget.existingSchedule!.grade,
        );

        context.read<CourseBloc>().add(UpdateScheduleEvent(
              courseId: widget.courseId,
              scheduleId: widget.existingSchedule!.id,
              updatedSchedule: updatedSchedule,
            ));
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourseBloc, CourseState>(
      listener: (context, state) {
        if (state is CourseActionSuccess) {
          Navigator.pop(context); // Close sheet on success
        } else if (state is CourseError) {
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
              // Schedule header card
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
                        Icons.schedule,
                        color: AppColors.primaryBlue,
                        size: 7.w,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.existingSchedule == null
                                  ? 'Create Regular Schedule'
                                  : 'Update Regular Schedule',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Weekly recurring class schedule',
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

              // Day selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2.w),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3.w),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 3.w,
                      ),
                    ),
                    style:
                        TextStyle(fontSize: 14.sp, color: AppColors.textDark),
                    value: _selectedDay,
                    items: _days.map((day) {
                      return DropdownMenuItem(
                        value: day,
                        child: Text(
                          day,
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDay = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a day';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              SizedBox(height: 4.w),

              // Time selection row
              Row(
                children: [
                  // Start time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 2.w),
                        InkWell(
                          onTap: () => _selectTime(context, true),
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: AppColors.backgroundDark,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(3.w),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: AppColors.primaryBlue,
                                  size: 5.w,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  _formatTimeOfDay(_startTime),
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 4.w),

                  // End time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 2.w),
                        InkWell(
                          onTap: () => _selectTime(context, false),
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: AppColors.backgroundDark,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(3.w),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: AppColors.primaryBlue,
                                  size: 5.w,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  _formatTimeOfDay(_endTime),
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.w),

              // Location
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2.w),
                  TextFormField(
                    controller: _locationController,
                    style: TextStyle(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: 'Enter class location',
                      hintStyle: TextStyle(fontSize: 14.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3.w),
                      ),
                      prefixIcon: Icon(Icons.location_on, size: 5.w),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 3.w,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a location';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              SizedBox(height: 6.w),

              // Duration indicator (optional helper)
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryBlue,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Class duration: ${_calculateDuration()}',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
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
                    child: BlocBuilder<CourseBloc, CourseState>(
                      builder: (context, state) {
                        final isLoading = state is CourseLoading;

                        return ElevatedButton(
                          onPressed: isLoading ? null : _saveSchedule,
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
                                  widget.existingSchedule == null
                                      ? 'Add Schedule'
                                      : 'Save Changes',
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

  String _calculateDuration() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final durationMinutes = endMinutes - startMinutes;

    if (durationMinutes <= 0) {
      return 'Invalid duration';
    }

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} $minutes minute${minutes > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''}';
    } else {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }
}
