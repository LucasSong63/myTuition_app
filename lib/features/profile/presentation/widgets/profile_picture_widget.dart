// lib/features/profile/presentation/widgets/profile_picture_widget.dart

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'cached_network_image.dart';

class ProfilePictureWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;
  final bool showEditButton;
  final bool isLoading;

  const ProfilePictureWidget({
    Key? key,
    required this.imageUrl,
    required this.size,
    this.onTap,
    this.onEditTap,
    this.showEditButton = true,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main profile picture
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white,
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2.w,
                  offset: Offset(0, 0.5.h),
                ),
              ],
            ),
            child: ClipOval(
              child: isLoading
                  ? _buildLoadingState()
                  : CachedProfileImage(
                      imageUrl: imageUrl,
                      size: size,
                    ),
            ),
          ),
        ),

        // Edit button
        if (showEditButton && onEditTap != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: isLoading ? null : onEditTap,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color:
                      isLoading ? AppColors.textMedium : AppColors.accentOrange,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white,
                    width: 0.5.w,
                  ),
                ),
                child: Icon(
                  isLoading ? Icons.hourglass_empty : Icons.camera_alt,
                  color: AppColors.white,
                  size: size * 0.12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: size,
      height: size,
      color: AppColors.backgroundDark,
      child: Center(
        child: CircularProgressIndicator(
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          strokeWidth: size * 0.02,
        ),
      ),
    );
  }
}
