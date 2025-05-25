// lib/features/courses/presentation/widgets/replacement_schedule_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/courses/domain/entities/course.dart';
import 'package:mytuition/features/courses/domain/entities/schedule.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_bloc.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_event.dart';
import 'package:mytuition/features/courses/presentation/bloc/course_state.dart';

class ReplacementScheduleBottomSheet {
  static Future<void> show({
    required BuildContext context,
    required Course course,
  }) async {
    // Get the existing bloc from the parent context
    final CourseBloc parentBloc = context.read<CourseBloc>();

    // Define the page content builder function
    WoltModalSheetPage pageBuilder(BuildContext context) {
      return WoltModalSheetPage(
        hasSabGradient: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        topBarTitle: Text(
          'Add Replacement Schedule',
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
                  child: _ReplacementScheduleContent(
                    course: course,
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

class _ReplacementScheduleContent extends StatefulWidget {
  final Course course;

  const _ReplacementScheduleContent({
    required this.course,
  });

  @override
  State<_ReplacementScheduleContent> createState() =>
      _ReplacementScheduleContentState();
}

class _ReplacementScheduleContentState
    extends State<_ReplacementScheduleContent> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _reasonController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  ScheduleType _scheduleType = ScheduleType.replacement;
  String? _replacesDate;

  @override
  void dispose() {
    _locationController.dispose();
    _reasonController.dispose();
    super.dispose();
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
              content: Text(state.message),
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
              // Course information header
              _buildCourseInfoHeader(),

              SizedBox(height: 3.h),

              // Schedule type selection
              _buildScheduleTypeSelector(),

              SizedBox(height: 3.h),

              // Date selection
              _buildDateSelector(),

              SizedBox(height: 2.h),

              // Time selection
              _buildTimeSelectors(),

              SizedBox(height: 2.h),

              // Location input
              _buildLocationInput(),

              SizedBox(height: 2.h),

              // Replaces date (for replacement schedules) - NOW INCLUDES FUTURE DATES
              if (_scheduleType == ScheduleType.replacement) ...[
                _buildReplacesDateSelector(),
                SizedBox(height: 2.h),
              ],

              // Reason input
              _buildReasonInput(),

              SizedBox(height: 3.h),

              // Warning if no date selected
              if (_selectedDate == null) _buildDateWarning(),

              SizedBox(height: 2.h),

              // Submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseInfoHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              width: 1.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: _getSubjectColor(widget.course.subject),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.event_repeat,
              color: AppColors.accentOrange,
              size: 7.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.course.subject,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Grade ${widget.course.grade} • Create replacement schedule',
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
    );
  }

  Widget _buildScheduleTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule Type',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: Card(
                color: _scheduleType == ScheduleType.replacement
                    ? AppColors.primaryBlue.withOpacity(0.1)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _scheduleType == ScheduleType.replacement
                        ? AppColors.primaryBlue
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: RadioListTile<ScheduleType>(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  title: Text(
                    'Replacement',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
                  ),
                  subtitle: Text(
                    'Makeup class',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  value: ScheduleType.replacement,
                  groupValue: _scheduleType,
                  onChanged: (value) {
                    setState(() {
                      _scheduleType = value!;
                    });
                  },
                  activeColor: AppColors.primaryBlue,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Card(
                color: _scheduleType == ScheduleType.extension
                    ? AppColors.primaryBlue.withOpacity(0.1)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _scheduleType == ScheduleType.extension
                        ? AppColors.primaryBlue
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: RadioListTile<ScheduleType>(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  title: Text(
                    'Extension',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
                  ),
                  subtitle: Text(
                    'Extended time',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  value: ScheduleType.extension,
                  groupValue: _scheduleType,
                  onChanged: (value) {
                    setState(() {
                      _scheduleType = value!;
                    });
                  },
                  activeColor: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule Date',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 1.h),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedDate == null
                    ? AppColors.error
                    : AppColors.primaryBlue.withOpacity(0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: _selectedDate == null
                      ? AppColors.error
                      : AppColors.primaryBlue,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDate != null
                            ? DateFormat('EEEE, MMMM d, yyyy')
                                .format(_selectedDate!)
                            : 'Select date for ${_scheduleType.toString().split('.').last} class',
                        style: TextStyle(
                          color: _selectedDate == null
                              ? AppColors.error
                              : AppColors.textDark,
                          fontWeight: _selectedDate != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 14.sp,
                        ),
                      ),
                      if (_selectedDate != null)
                        Text(
                          _getDateDescription(_selectedDate!),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textMedium,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: _selectedDate == null
                      ? AppColors.error
                      : AppColors.primaryBlue,
                  size: 6.w,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelectors() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start Time',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 1.h),
              InkWell(
                onTap: () => _selectTime(context, true),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          color: AppColors.primaryBlue, size: 5.w),
                      SizedBox(width: 2.w),
                      Text(
                        _formatTimeOfDay(_startTime),
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14.sp),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'End Time',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 1.h),
              InkWell(
                onTap: () => _selectTime(context, false),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          color: AppColors.primaryBlue, size: 5.w),
                      SizedBox(width: 2.w),
                      Text(
                        _formatTimeOfDay(_endTime),
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14.sp),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInput() {
    return Column(
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
        SizedBox(height: 1.h),
        TextFormField(
          controller: _locationController,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: 'Enter class location',
            hintStyle: TextStyle(fontSize: 14.sp),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.location_on, size: 5.w),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a location';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildReplacesDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Replaces Class Date (Optional)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          'Select which regular class this replacement is for',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textMedium,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 1.h),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            hintText: 'Select original class date being replaced',
            hintStyle: TextStyle(fontSize: 14.sp),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.history, size: 5.w),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          ),
          style: TextStyle(fontSize: 14.sp, color: AppColors.textDark),
          value: _replacesDate,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'Not replacing a specific date',
                style: TextStyle(fontSize: 14.sp, fontStyle: FontStyle.italic),
              ),
            ),
            ..._getAllPossibleClassDates().map((dateInfo) {
              return DropdownMenuItem<String>(
                value: dateInfo['date'] as String,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateInfo['displayText'] as String,
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      dateInfo['status'] as String,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: (dateInfo['isPast'] as bool)
                            ? AppColors.error
                            : AppColors.accentTeal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _replacesDate = value;
            });
          },
        ),
        if (_replacesDate != null) ...[
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.primaryBlue, size: 4.w),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    _getReplacementInfo(_replacesDate!),
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReasonInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _scheduleType == ScheduleType.replacement
              ? 'Reason for Replacement'
              : 'Reason for Extension',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _reasonController,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: _scheduleType == ScheduleType.replacement
                ? 'e.g., Holiday makeup, Weather cancellation, Student request'
                : 'e.g., Extra practice, Exam preparation, Extended lesson',
            hintStyle: TextStyle(fontSize: 13.sp),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.notes, size: 5.w),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildDateWarning() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange[700], size: 5.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Please select a date for the ${_scheduleType.toString().split('.').last} schedule.',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<CourseBloc, CourseState>(
      builder: (context, state) {
        final isLoading = state is CourseLoading;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                (_selectedDate != null && !isLoading) ? _submitSchedule : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 6.w,
                    height: 6.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Add ${_scheduleType.toString().split('.').last.capitalize()}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
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

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _checkForConflicts();
      });
    }
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

  void _submitSchedule() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      // Create DateTime objects from TimeOfDay
      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Get day name from specific date
      const dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      final dayName = dayNames[_selectedDate!.weekday - 1];

      // Create unique ID for replacement schedule
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final scheduleId =
          '${widget.course.id}-${_scheduleType.toString().split('.').last}-$timestamp';

      // Create Schedule entity
      final schedule = Schedule(
        id: scheduleId,
        courseId: widget.course.id,
        day: dayName,
        startTime: startDateTime,
        endTime: endDateTime,
        location: _locationController.text,
        subject: widget.course.subject,
        grade: widget.course.grade,
        type: _scheduleType,
        specificDate: _selectedDate,
        replacesDate: _replacesDate,
        reason:
            _reasonController.text.isNotEmpty ? _reasonController.text : null,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Add schedule via BLoC
      context.read<CourseBloc>().add(
            AddScheduleEvent(
              courseId: widget.course.id,
              schedule: schedule,
            ),
          );
    }
  }

  void _checkForConflicts() {
    if (_selectedDate == null) return;

    // Check if there's already a schedule on this date
    final dayName = _getDayName(_selectedDate!.weekday);
    final hasRegularClass = widget.course.schedules.any(
      (schedule) => schedule.day == dayName && schedule.isRegular,
    );

    if (hasRegularClass) {
      // Show warning about regular class conflict
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Note: There is already a regular $dayName class scheduled.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // UPDATED: Now includes both past AND future dates
  List<Map<String, dynamic>> _getAllPossibleClassDates() {
    final now = DateTime.now();
    final possibleDates = <Map<String, dynamic>>[];

    // Get past 30 days regular class dates that might have been missed
    for (int i = 1; i <= 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dayName = _getDayName(date.weekday);

      final hasRegularClass = widget.course.schedules.any(
        (schedule) => schedule.day == dayName && schedule.isRegular,
      );

      if (hasRegularClass) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        possibleDates.add({
          'date': dateStr,
          'displayText': DateFormat('MMM d, yyyy (EEEE)').format(date),
          'status': 'Past class (missed)',
          'isPast': true,
        });
      }
    }

    // NEW: Get future 60 days regular class dates for advance planning
    for (int i = 1; i <= 60; i++) {
      final date = now.add(Duration(days: i));
      final dayName = _getDayName(date.weekday);

      final hasRegularClass = widget.course.schedules.any(
        (schedule) => schedule.day == dayName && schedule.isRegular,
      );

      if (hasRegularClass) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        possibleDates.add({
          'date': dateStr,
          'displayText': DateFormat('MMM d, yyyy (EEEE)').format(date),
          'status': 'Future class (advance planning)',
          'isPast': false,
        });
      }
    }

    // Sort by date: past dates first (most recent), then future dates
    possibleDates.sort((a, b) {
      final dateA = DateTime.parse(a['date'] as String);
      final dateB = DateTime.parse(b['date'] as String);

      final isPastA = a['isPast'] as bool;
      final isPastB = b['isPast'] as bool;

      // If one is past and one is future, past comes first
      if (isPastA && !isPastB) return -1;
      if (!isPastA && isPastB) return 1;

      // If both are past, more recent first (descending)
      if (isPastA && isPastB) return dateB.compareTo(dateA);

      // If both are future, earlier first (ascending)
      return dateA.compareTo(dateB);
    });

    return possibleDates.take(20).toList(); // Limit to 20 total dates
  }

  String _getReplacementInfo(String replacementDate) {
    final date = DateTime.parse(replacementDate);
    final isPast = date.isBefore(DateTime.now());

    if (isPast) {
      return 'This replacement is for a missed class on ${DateFormat('MMM d, yyyy').format(date)}.';
    } else {
      return 'This replacement is planned for the future class on ${DateFormat('MMM d, yyyy').format(date)}. Students will be notified in advance.';
    }
  }

  String _getDateDescription(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return 'In $difference days';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return 'In $weeks ${weeks == 1 ? 'week' : 'weeks'}';
    } else {
      final months = (difference / 30).floor();
      return 'In $months ${months == 1 ? 'month' : 'months'}';
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return AppColors.mathSubject;
      case 'science':
        return AppColors.scienceSubject;
      case 'english':
        return AppColors.englishSubject;
      case 'bahasa malaysia':
        return AppColors.bahasaSubject;
      case 'chinese':
        return AppColors.chineseSubject;
      default:
        return AppColors.primaryBlue;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
