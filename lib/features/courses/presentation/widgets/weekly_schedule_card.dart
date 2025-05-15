// lib/features/courses/presentation/widgets/weekly_schedule_card.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/entities/course.dart';

class WeeklyScheduleCard extends StatelessWidget {
  final List<Schedule> schedules;

  // Define constants for the timetable
  static const int START_HOUR = 8; // 8 AM
  static const int END_HOUR = 22; // 10 PM
  static const List<String> DAYS = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  const WeeklyScheduleCard({
    Key? key,
    required this.schedules,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: 35.h, // 35% of screen height for the timetable
        child: Column(
          children: [
            // Title and legend
            _buildHeader(),

            // Timetable body (day headers + time grid)
            Expanded(
              child: _buildTimetable(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Schedule',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Tap on a class for details',
            style: TextStyle(
              fontSize: 9.sp,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetable(BuildContext context) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Day headers
            _buildDayHeaders(),

            // Time grid with course blocks
            Container(
              height: 24.h, // Allow vertical scrolling for the grid
              child: SingleChildScrollView(
                child: SizedBox(
                  // 60.w minimum to ensure horizontal scrolling on smaller screens
                  width: max(60.w, 12.w * DAYS.length + 8.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time labels column
                      _buildTimeLabels(),

                      // Day columns with course blocks
                      Expanded(
                        child: Stack(
                          children: [
                            // Background grid
                            _buildGridLines(),

                            // Course blocks
                            ..._buildCourseBlocks(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayHeaders() {
    return Container(
      height: 4.h,
      color: AppColors.backgroundLight,
      child: Row(
        children: [
          // Empty space for time labels column
          SizedBox(width: 8.w),

          // Day labels
          ...DAYS
              .map((day) => Container(
                    width: 12.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColors.divider),
                        bottom: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: Text(
                      day.substring(0, 3), // Show first 3 letters only
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildTimeLabels() {
    final int totalHours = END_HOUR - START_HOUR;
    final List<Widget> timeLabels = [];

    for (int i = 0; i <= totalHours; i++) {
      final hour = START_HOUR + i;
      final formattedHour = hour < 12
          ? '$hour AM'
          : hour == 12
              ? '12 PM'
              : '${hour - 12} PM';

      timeLabels.add(
        Container(
          height: 6.h,
          width: 8.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: AppColors.divider),
              bottom: i < totalHours
                  ? BorderSide(color: AppColors.divider)
                  : BorderSide.none,
            ),
          ),
          child: Text(
            formattedHour,
            style: TextStyle(
              fontSize: 8.sp,
              color: AppColors.textMedium,
            ),
          ),
        ),
      );
    }

    return Column(children: timeLabels);
  }

  Widget _buildGridLines() {
    final int totalHours = END_HOUR - START_HOUR;
    final double dayWidth = 12.w;
    final double hourHeight = 6.h;

    return SizedBox(
      width: dayWidth * DAYS.length,
      height: hourHeight * totalHours,
      child: CustomPaint(
        painter: GridPainter(
          daysCount: DAYS.length,
          hoursCount: totalHours,
          dayWidth: dayWidth,
          hourHeight: hourHeight,
          lineColor: AppColors.divider,
        ),
      ),
    );
  }

  List<Widget> _buildCourseBlocks(BuildContext context) {
    final List<Widget> courseBlocks = [];
    final double dayWidth = 12.w;
    final double hourHeight = 6.h;

    for (Schedule schedule in schedules) {
      // Get day index (0 = Sunday, 1 = Monday, etc.)
      final int dayIndex = DAYS.indexOf(schedule.day);
      if (dayIndex == -1) continue; // Skip if day not found

      // Calculate start and end positions
      final double startHour =
          schedule.startTime.hour + schedule.startTime.minute / 60;
      final double endHour =
          schedule.endTime.hour + schedule.endTime.minute / 60;

      if (startHour < START_HOUR || endHour > END_HOUR)
        continue; // Skip if outside our time range

      final double top = (startHour - START_HOUR) * hourHeight;
      final double height = (endHour - startHour) * hourHeight;
      final double left = dayIndex * dayWidth;

      courseBlocks.add(
        Positioned(
          top: top,
          left: left,
          width: dayWidth,
          height: height,
          child: Padding(
            padding: EdgeInsets.all(2),
            child: GestureDetector(
              onTap: () {
                // Navigate to course details
                context.push('/student/courses/${schedule.courseId}');
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _getSubjectColor(schedule.subject).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.5.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject name
                    Text(
                      schedule.subject,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 0.2.h),
                    // Time
                    Text(
                      '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7.sp,
                      ),
                    ),
                    // Only show location if there's enough space
                    if (height > 5.h) ...[
                      SizedBox(height: 0.2.h),
                      // Location
                      Text(
                        schedule.location,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 7.sp,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return courseBlocks;
  }

  // Helper method to format time (e.g., "9:30")
  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    final formattedHour = hour <= 12 ? hour : hour - 12;
    return '$formattedHour:$minute $period';
  }

  // Helper method to get color based on subject
  Color _getSubjectColor(String subject) {
    subject = subject.toLowerCase();
    if (subject.contains('math')) return AppColors.mathSubject;
    if (subject.contains('science')) return AppColors.scienceSubject;
    if (subject.contains('english')) return AppColors.englishSubject;
    if (subject.contains('bahasa')) return AppColors.bahasaSubject;
    if (subject.contains('chinese')) return AppColors.chineseSubject;
    return AppColors.primaryBlue;
  }

  // Helper method to calculate maximum of two doubles
  double max(double a, double b) {
    return a > b ? a : b;
  }
}

// CustomPainter for drawing the grid lines
class GridPainter extends CustomPainter {
  final int daysCount;
  final int hoursCount;
  final double dayWidth;
  final double hourHeight;
  final Color lineColor;

  GridPainter({
    required this.daysCount,
    required this.hoursCount,
    required this.dayWidth,
    required this.hourHeight,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    // Draw vertical lines (day separators)
    for (int i = 0; i <= daysCount; i++) {
      final x = i * dayWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, hoursCount * hourHeight),
        paint,
      );
    }

    // Draw horizontal lines (hour separators)
    for (int i = 0; i <= hoursCount; i++) {
      final y = i * hourHeight;
      canvas.drawLine(
        Offset(0, y),
        Offset(daysCount * dayWidth, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
