// lib/features/student_management/presentation/widgets/student_list_item.dart

import 'package:flutter/material.dart';
import 'package:mytuition/config/theme/app_colors.dart';
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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Profile picture or avatar
              _buildAvatar(student.name, student.profilePictureUrl),
              const SizedBox(width: 16),

              // Student info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Student ID
                        Expanded(
                          child: Text(
                            'ID: ${student.studentId}',
                            style: TextStyle(
                              color: AppColors.textMedium,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Grade
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlueLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Grade ${student.grade}',
                            style: TextStyle(
                              fontSize: 12,
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
          radius: 24,
          backgroundImage: NetworkImage(profilePictureUrl),
        ),
      );
    }

    // Otherwise show initials
    return Hero(
      tag: 'student_avatar_${student.studentId}',
      child: CircleAvatar(
        radius: 24,
        backgroundColor: _getAvatarColor(name),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
