// lib/features/attendance/presentation/widgets/manage/quick_filter_chips.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';

class QuickFilterChips extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime start, DateTime end) onDateRangeChanged;

  const QuickFilterChips({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
  }) : super(key: key);

  void _clearDateFilter() {
    // This would need to be handled by parent
    // For now, we'll just trigger a 7-day range
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 7));
    onDateRangeChanged(start, end);
  }

  void _setLast30Days() {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 30));
    onDateRangeChanged(start, end);
  }

  void _setThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    onDateRangeChanged(start, end);
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onPressed) {
    bool isActive = false;
    if (label == 'Last 7 days') {
      isActive = startDate == null && endDate == null;
    } else if (label == 'Last 30 days' &&
        startDate != null &&
        endDate != null) {
      final daysDiff = endDate!.difference(startDate!).inDays;
      isActive = daysDiff == 30;
    } else if (label == 'This month' && startDate != null && endDate != null) {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      isActive = startDate!.year == monthStart.year &&
          startDate!.month == monthStart.month &&
          startDate!.day == monthStart.day &&
          endDate!.year == monthEnd.year &&
          endDate!.month == monthEnd.month &&
          endDate!.day == monthEnd.day;
    }

    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          color: isActive ? Colors.white : AppColors.primaryBlue,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onPressed: onPressed,
      backgroundColor: isActive
          ? AppColors.primaryBlue
          : AppColors.primaryBlue.withOpacity(0.1),
      side: BorderSide(
        color: isActive
            ? AppColors.primaryBlue
            : AppColors.primaryBlue.withOpacity(0.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickFilterChip('Last 7 days', _clearDateFilter),
          SizedBox(width: 2.w),
          _buildQuickFilterChip('Last 30 days', _setLast30Days),
          SizedBox(width: 2.w),
          _buildQuickFilterChip('This month', _setThisMonth),
        ],
      ),
    );
  }
}
