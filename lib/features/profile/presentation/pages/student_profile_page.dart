// lib/features/profile/presentation/pages/student_profile_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mytuition/features/profile/presentation/widgets/edit_profile_bottom_sheet.dart';
import 'package:mytuition/features/profile/presentation/widgets/profile_header.dart';
import 'package:mytuition/features/profile/presentation/widgets/student_payment_info_card.dart';
import 'package:mytuition/features/profile/presentation/widgets/student_payment_bottom_sheet.dart';
import 'package:sizer/sizer.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import 'package:mytuition/features/payments/presentation/bloc/payment_info_bloc.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_event.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_state.dart';

import '../../../auth/presentation/bloc/auth_event.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({Key? key}) : super(key: key);

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    // Load payment info when the page loads
    try {
      context.read<PaymentInfoBloc>().add(LoadPaymentInfoEvent());
    } catch (e) {
      print('PaymentInfoBloc not available in profile page');
    }

    // Load payment summary for outstanding information
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated && authState.user.studentId != null) {
      try {
        context.read<ProfileBloc>().add(
              LoadStudentPaymentSummaryEvent(
                  studentId: authState.user.studentId!),
            );
      } catch (e) {
        print('Error loading payment summary: $e');
      }
    }
  }

  Future<void> _refreshPage() async {
    // Refresh all data
    try {
      context.read<PaymentInfoBloc>().add(LoadPaymentInfoEvent());

      // Also refresh payment summary
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated && authState.user.studentId != null) {
        context.read<ProfileBloc>().add(
              LoadStudentPaymentSummaryEvent(
                  studentId: authState.user.studentId!),
            );
      }

      // Add small delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('Error refreshing page: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            // Refresh the page after profile update
            _refreshPage();
          }
        },
        builder: (context, profileState) {
          return BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is! Authenticated) {
                return const Center(
                  child: Text('Please log in to view your profile'),
                );
              }

              final user = authState.user;
              final isLoading = profileState is ProfileLoading;

              return RefreshIndicator(
                onRefresh: _refreshPage,
                color: AppColors.primaryBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Profile Header Section (moved to body)
                      _buildProfileHeader(user, isLoading),

                      // Main Content
                      Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 2.h),

                            // Student ID QR Code Section (NEW)
                            _buildStudentIdQrSection(user),

                            SizedBox(height: 2.5.h),

                            // Personal Information Card
                            _buildPersonalInfoCard(user),

                            SizedBox(height: 2.5.h),

                            // Payment Information Section
                            _buildSectionHeader("💳 Tutor's Bank Information"),
                            SizedBox(height: 1.5.h),
                            _buildPaymentInfoSection(user),

                            SizedBox(height: 2.5.h),

                            // Help & Support Section
                            _buildSectionHeader('🔧 Help & Support'),
                            SizedBox(height: 1.5.h),
                            _buildHelpSupportCard(),

                            SizedBox(height: 4.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // NEW: Student ID QR Code Section
  Widget _buildStudentIdQrSection(user) {
    final studentId = user.studentId ?? 'Not assigned';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.qr_code,
                  color: AppColors.primaryBlue,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student ID',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          Icon(
                            Icons.badge,
                            color: AppColors.primaryBlue,
                            size: 4.w,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            studentId,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // QR Code
            if (studentId != 'Not assigned') ...[
              GestureDetector(
                onTap: () => _showFullScreenQrCode(context, studentId),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(3.w),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 1.w,
                        offset: Offset(0, 0.5.h),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: studentId,
                        version: QrVersions.auto,
                        size: 35.w,
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.textDark,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        embeddedImage: null, // Can add logo if needed
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fullscreen,
                            color: AppColors.primaryBlue,
                            size: 4.w,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Tap to view full screen',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 2.h),

              // Instruction text
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2.w),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryBlue,
                      size: 5.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'Show this QR code to your tutor for attendance marking',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.primaryBlue,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // No student ID assigned state
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3.w),
                  border: Border.all(
                    color: AppColors.backgroundDark,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_scanner_outlined,
                      size: 12.w,
                      color: AppColors.textMedium,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'QR Code Not Available',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Your Student ID has not been assigned yet',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textMedium,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Profile header now in body instead of app bar
  Widget _buildProfileHeader(user, bool isLoading) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlueDark,
          ],
        ),
      ),
      child: SafeArea(
        top: false, // Don't add extra top padding since we have AppBar
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
          child: Column(
            children: [
              // Profile Picture - Fixed to show actual image
              _buildProfilePicture(user, isLoading),

              SizedBox(height: 2.5.h),

              // User Name
              Text(
                user.name ?? 'Student',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 0.8.h),

              // User Email
              Text(
                user.email ?? '',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 2.h),

              // Edit Profile Button
              ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _showEditProfileBottomSheet(context, user),
                icon: isLoading
                    ? SizedBox(
                        width: 4.w,
                        height: 4.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryBlue),
                        ),
                      )
                    : Icon(Icons.edit, size: 4.w),
                label: Text(
                  isLoading ? 'Updating...' : 'Edit Profile',
                  style: TextStyle(fontSize: 13.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.w),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.2.h),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fixed profile picture widget
  Widget _buildProfilePicture(user, bool isLoading) {
    return Stack(
      children: [
        // Main profile picture container
        GestureDetector(
          onTap: () => _viewProfilePicture(user.profilePictureUrl),
          child: Container(
            width: 28.w,
            height: 28.w,
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
                  : _buildProfileImage(user.profilePictureUrl),
            ),
          ),
        ),

        // Edit button
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: isLoading
                ? null
                : () => _showProfilePictureOptions(context, user.docId),
            child: Container(
              width: 7.w,
              height: 7.w,
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
                size: 3.5.w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Fixed profile image loading
  Widget _buildProfileImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: 28.w,
        height: 28.w,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingState();
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading profile image: $error');
          return _buildDefaultAvatar();
        },
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildLoadingState() {
    return Container(
      width: 28.w,
      height: 28.w,
      color: AppColors.backgroundDark,
      child: Center(
        child: CircularProgressIndicator(
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          strokeWidth: 0.5.w,
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 28.w,
      height: 28.w,
      color: AppColors.backgroundDark,
      child: Icon(
        Icons.person,
        size: 12.w,
        color: AppColors.textMedium,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildPersonalInfoCard(user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: AppColors.primaryBlue,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.5.h),
            _buildInfoRow('📧', 'Email', user.email ?? 'Not provided'),
            SizedBox(height: 2.h),
            _buildInfoRow('📱', 'Phone', user.phone ?? 'Not provided'),
            SizedBox(height: 2.h),
            _buildInfoRow(
                '🎓', 'Grade', user.grade?.toString() ?? 'Not specified'),
            SizedBox(height: 2.h),
            _buildInfoRow('🆔', 'Student ID', user.studentId ?? 'Not assigned'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: TextStyle(fontSize: 20.sp),
        ),
        SizedBox(width: 3.w),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfoSection(user) {
    return Column(
      children: [
        // Payment History & Outstanding Button (moved to top)
        if (user.studentId != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _showPaymentDetailsBottomSheet(context, user.studentId!),
              icon: Icon(Icons.account_balance_wallet, size: 5.w),
              label: Text(
                'View Payment Details',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 1.8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.w),
                ),
                elevation: 2,
              ),
            ),
          ),
          SizedBox(height: 3.h),
        ],

        // Payment Methods Card (improved version)
        () {
          try {
            return BlocBuilder<PaymentInfoBloc, PaymentInfoState>(
              builder: (context, paymentState) {
                if (paymentState is PaymentInfoLoading) {
                  return _buildLoadingCard();
                }
                if (paymentState is PaymentInfoLoaded) {
                  // Get payment summary data for outstanding info
                  return BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, profileState) {
                      bool hasOutstanding = false;
                      double totalOutstanding = 0.0;

                      if (profileState is StudentPaymentSummaryLoaded) {
                        hasOutstanding =
                            profileState.paymentSummary.hasOutstandingPayments;
                        totalOutstanding =
                            profileState.paymentSummary.totalOutstanding;
                      }

                      return StudentPaymentInfoCard(
                        paymentInfo: paymentState.paymentInfo,
                        hasOutstandingPayments: hasOutstanding,
                        totalOutstanding: totalOutstanding,
                      );
                    },
                  );
                }
                if (paymentState is PaymentInfoError) {
                  return _buildErrorCard(
                    'Unable to load payment information',
                    paymentState.message,
                    () => context
                        .read<PaymentInfoBloc>()
                        .add(LoadPaymentInfoEvent()),
                  );
                }
                return _buildEmptyPaymentCard();
              },
            );
          } catch (e) {
            return _buildUnavailablePaymentCard();
          }
        }(),

        // Show message if no student ID (moved to bottom)
        if (user.studentId == null) ...[
          SizedBox(height: 2.h),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.w)),
            child: Padding(
              padding: EdgeInsets.all(6.w),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 10.w,
                    color: AppColors.textLight,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Payment Details Unavailable',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Your Student ID has not been assigned yet.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHelpSupportCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
      child: Column(
        children: [
          ProfileMenuItem(
            icon: Icons.help_outline,
            iconColor: AppColors.accentTeal,
            title: 'Help Center',
            subtitle: 'Get help and find answers',
            onTap: () {
              // Navigate to help center
            },
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.bug_report_outlined,
            iconColor: AppColors.warning,
            title: 'Report Issue',
            subtitle: 'Report bugs and issues',
            onTap: () {
              // Navigate to report issue
            },
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.info_outline,
            iconColor: AppColors.primaryBlue,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              // Show about dialog
            },
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.logout,
            iconColor: AppColors.error,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
            SizedBox(width: 4.w),
            Text(
              'Loading payment information...',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String title, String message, VoidCallback onRetry) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 6.w),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textMedium,
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPaymentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          children: [
            Icon(
              Icons.payment_outlined,
              size: 12.w,
              color: AppColors.textLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No Payment Information',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Payment information will be available once your tutor sets it up.',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailablePaymentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 12.w,
              color: AppColors.textLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'Payment Information Unavailable',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Payment information service is currently unavailable.',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _viewProfilePicture(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final imageProvider = NetworkImage(imageUrl);
      showImageViewer(
        context,
        imageProvider,
        onViewerDismissed: () {
          print("Profile picture viewer dismissed");
        },
        swipeDismissible: true,
        doubleTapZoomable: true,
      );
    }
  }

  void _showFullScreenQrCode(BuildContext context, String studentId) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black87,
        child: Scaffold(
          backgroundColor: Colors.black87,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.close,
                color: AppColors.white,
                size: 28,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Student ID: $studentId',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Full screen QR code
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(4.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 3.w,
                        offset: Offset(0, 1.h),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: studentId,
                    version: QrVersions.auto,
                    size: 70.w,
                    // Much larger for full screen
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.textDark,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),

                SizedBox(height: 4.h),

                // Instructions
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3.w),
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: AppColors.white,
                        size: 8.w,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Show this QR code to your tutor',
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Your tutor will scan this code to mark your attendance',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.white.withOpacity(0.8),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 4.h),

                // Close button
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.textDark,
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 1.5.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3.w),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileBottomSheet(BuildContext context, user) {
    EditProfileBottomSheet.show(
      context: context,
      user: user,
      onSave: (name, phone) {
        context.read<ProfileBloc>().add(
              UpdateProfileEvent(
                userId: user.docId,
                name: name,
                phone: phone,
              ),
            );
      },
    );
  }

  void _showProfilePictureOptions(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10.w,
                height: 0.5.h,
                margin: EdgeInsets.only(top: 1.5.h, bottom: 2.5.h),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(0.5.w),
                ),
              ),
              Text(
                'Profile Picture',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 2.5.h),
              ListTile(
                leading:
                    const Icon(Icons.camera_alt, color: AppColors.primaryBlue),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, userId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: AppColors.accentOrange),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, userId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  context.read<ProfileBloc>().add(
                        RemoveProfilePictureEvent(userId: userId),
                      );
                },
              ),
              SizedBox(height: 2.5.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, String userId) async {
    // Show loading immediately
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Processing image...'),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
        duration: const Duration(seconds: 2),
      ),
    );

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1080, // Higher resolution
      maxHeight: 1080,
      imageQuality: 90, // Higher quality
    );

    if (image != null) {
      context.read<ProfileBloc>().add(
            UpdateProfilePictureEvent(
              userId: userId,
              imageFile: File(image.path),
            ),
          );
    } else {
      // Hide loading if user cancelled
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetailsBottomSheet(BuildContext context, String studentId) {
    StudentPaymentBottomSheet.show(
      context: context,
      studentId: studentId,
    );
  }
}
