// lib/features/student_management/presentation/widgets/student_list_item.dart

import 'package:flutter/material.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:sizer/sizer.dart';
import '../../domain/entities/student.dart';

class StudentListItem extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const StudentListItem({
    Key? key,
    required this.student,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 3.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(3.w),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              // Profile picture or avatar
              _buildAvatar(student.name, student.profilePictureUrl),
              SizedBox(width: 4.w),

              // Student info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.w),
                    Row(
                      children: [
                        // Student ID
                        Expanded(
                          child: Text(
                            'ID: ${student.studentId}',
                            style: TextStyle(
                              color: AppColors.textMedium,
                              fontSize: 14.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 2.w),

                        // Grade
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 1.5.w,
                            vertical: 0.5.w,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlueLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2.w),
                          ),
                          child: Text(
                            'Grade ${student.grade}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String? profilePictureUrl) {
    // If there's a profile picture, show it
    if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
      return Hero(
        tag: 'student_avatar_${student.studentId}',
        child: CircleAvatar(
          radius: 6.w,
          backgroundImage: NetworkImage(profilePictureUrl),
        ),
      );
    }

    // Otherwise show initials
    return Hero(
      tag: 'student_avatar_${student.studentId}',
      child: CircleAvatar(
        radius: 6.w,
        backgroundColor: _getAvatarColor(name),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final List<Color> colors = [
      AppColors.primaryBlue,
      AppColors.accentOrange,
      AppColors.accentTeal,
      AppColors.mathSubject,
      AppColors.scienceSubject,
      AppColors.englishSubject,
      AppColors.bahasaSubject,
      AppColors.chineseSubject,
    ];

    if (name.isEmpty) return colors[0];

    // Use a simple hash function to get a consistent color for the same name
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = (hash + name.codeUnitAt(i)) % colors.length;
    }

    return colors[hash];
  }
}
