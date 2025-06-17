// lib/features/attendance/presentation/widgets/manage/attendance_app_bar.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';

class AttendanceAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String courseName;
  final TabController tabController;
  final VoidCallback onDateRangeFilter;
  final VoidCallback onClearFilter;
  final bool hasActiveFilter;

  const AttendanceAppBar({
    Key? key,
    required this.courseName,
    required this.tabController,
    required this.onDateRangeFilter,
    required this.onClearFilter,
    required this.hasActiveFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        'Manage Attendance - $courseName',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      bottom: TabBar(
        controller: tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(text: 'Summary'),
          Tab(text: 'History'),
        ],
      ),
      actions: [
        IconButton(
          onPressed: onDateRangeFilter,
          icon: Icon(
            Icons.date_range,
            size: 6.w,
          ),
          tooltip: 'Filter by date range',
        ),
        if (hasActiveFilter)
          IconButton(
            onPressed: onClearFilter,
            icon: Icon(
              Icons.clear,
              size: 6.w,
            ),
            tooltip: 'Clear filter',
          ),
        SizedBox(width: 2.w),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + kTextTabBarHeight);
}
