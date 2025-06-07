// lib/features/student_dashboard/presentation/widgets/upcoming_classes_widget.dart

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import '../../domain/entities/student_dashboard_stats.dart';

class UpcomingClassesWidget extends StatelessWidget {
  final List<UpcomingClass> upcomingClasses;
  final VoidCallback? onViewAll;

  const UpcomingClassesWidget({
    Key? key,
    required this.upcomingClasses,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final todayClasses = upcomingClasses.where((c) => c.isToday).toList();
    final nextFewClasses = upcomingClasses.take(3).toList();

    return Card(
      elevation: 0.5.w,
      shadowColor: AppColors.accentTeal.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.w),
          gradient: LinearGradient(
            colors: [
              AppColors.accentTeal.withOpacity(0.1),
              AppColors.accentTeal.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with dynamic emoji
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Text(
                        _getDynamicClassEmoji(),
                        // 🎯 Dynamic emoji based on time
                        style: TextStyle(fontSize: 6.w),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Upcoming Classes',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                if (onViewAll != null)
                  InkWell(
                    onTap: onViewAll,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(1.5.w),
                      ),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.accentTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 3.h),

            // Today's classes section (if any)
            if (todayClasses.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(3.w),
                  border: Border.all(
                    color: AppColors.accentTeal.withOpacity(0.3),
                    width: 0.3.w,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getTodayEmoji(), // 🎯 Dynamic today emoji
                          style: TextStyle(fontSize: 4.w),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentTeal,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: AppColors.accentTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(1.w),
                          ),
                          child: Text(
                            '${todayClasses.length} class${todayClasses.length == 1 ? '' : 'es'}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.accentTeal,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    ...todayClasses.map(
                        (class_) => _buildClassItem(class_, isToday: true)),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
            ],

            // This week section
            if (nextFewClasses.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    '🎯',
                    style: TextStyle(fontSize: 4.w),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'This Week',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              ...nextFewClasses.map((class_) => _buildClassItem(class_)),
            ] else ...[
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Column(
                    children: [
                      Text(
                        '🎓',
                        style: TextStyle(fontSize: 12.w),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No upcoming classes this week',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClassItem(UpcomingClass class_, {bool isToday = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.accentTeal.withOpacity(0.1)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(3.w),
        border: isToday
            ? Border.all(
                color: AppColors.accentTeal.withOpacity(0.3), width: 0.3.w)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Subject emoji
              Text(
                _getClassTypeEmoji(class_),
                style: TextStyle(fontSize: 4.w),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  class_.displayTitle,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (class_.isReplacement)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(1.w),
                  ),
                  child: Text(
                    'Replacement',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 3.5.w,
                color: AppColors.textMedium,
              ),
              SizedBox(width: 1.w),
              Text(
                class_.timeRange,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textMedium,
                ),
              ),
              SizedBox(width: 3.w),
              Icon(
                Icons.location_on,
                size: 3.5.w,
                color: AppColors.textMedium,
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  class_.location,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textMedium,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (!class_.isToday) ...[
            SizedBox(height: 0.5.h),
            Text(
              class_.day,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🎯 Dynamic emoji based on current time of day
  String _getDynamicClassEmoji() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      return '🌅'; // Morning classes
    } else if (hour >= 12 && hour < 17) {
      return '☀️'; // Afternoon classes
    } else if (hour >= 17 && hour < 20) {
      return '🌆'; // Evening classes
    } else {
      return '🌙'; // Night/late classes
    }
  }

  /// 🎯 Dynamic emoji for "Today" based on current time
  String _getTodayEmoji() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      return '🌤️'; // Morning
    } else if (hour >= 12 && hour < 17) {
      return '☀️'; // Afternoon
    } else if (hour >= 17 && hour < 20) {
      return '🌅'; // Evening
    } else {
      return '🌙'; // Night
    }
  }

  /// Get emoji based on class type/subject
  String _getClassTypeEmoji(UpcomingClass class_) {
    switch (class_.subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return '🔢';
      case 'science':
        return '🔬';
      case 'english':
        return '📚';
      case 'bahasa malaysia':
      case 'bahasa':
        return '🇲🇾';
      case 'chinese':
        return '🈺';
      default:
        return '📖';
    }
  }
}
