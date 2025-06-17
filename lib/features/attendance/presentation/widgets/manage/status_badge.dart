// lib/features/attendance/presentation/widgets/manage/status_badge.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const StatusBadge({
    Key? key,
    required this.label,
    required this.count,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
