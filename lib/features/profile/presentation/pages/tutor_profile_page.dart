// lib/features/profile/presentation/pages/tutor_profile_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mytuition/config/router/route_names.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_event.dart';
import 'package:mytuition/features/profile/presentation/widgets/edit_profile_bottom_sheet.dart';
import 'package:mytuition/features/profile/presentation/widgets/profile_header.dart';
import 'package:sizer/sizer.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import 'package:mytuition/features/payments/presentation/bloc/payment_info_bloc.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_event.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_state.dart';

class TutorProfilePage extends StatefulWidget {
  const TutorProfilePage({Key? key}) : super(key: key);

  @override
  State<TutorProfilePage> createState() => _TutorProfilePageState();
}

class _TutorProfilePageState extends State<TutorProfilePage> {
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
  }

  Future<void> _refreshPage() async {
    // Refresh all data
    try {
      context.read<PaymentInfoBloc>().add(LoadPaymentInfoEvent());
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
        title: const Text('Profile'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // Removed reload and settings buttons as requested
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

                            // Personal Information Card
                            _buildPersonalInfoCard(user),

                            SizedBox(height: 2.5.h),

                            // Business Management Section
                            _buildSectionHeader('💼 Business Management'),
                            SizedBox(height: 1.5.h),
                            _buildBusinessManagementCard(),

                            SizedBox(height: 2.5.h),

                            // Payment Management Section
                            _buildSectionHeader('💳 Payment Management'),
                            SizedBox(height: 1.5.h),
                            _buildPaymentManagementCard(),

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
              _buildProfilePicture(user, isLoading),

              SizedBox(height: 2.5.h),

              // User Name
              Text(
                user.name ?? 'Tutor',
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
                  fontSize: 15.sp,
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
            _buildInfoRow('👨‍🏫', 'Role', 'Tutor'),
            SizedBox(height: 2.h),
            _buildInfoRow(
                '📚', 'Subjects', user.subjects?.join(', ') ?? 'Not specified'),
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
              fontSize: 15.sp,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessManagementCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
      child: Column(
        children: [
          ProfileMenuItem(
            icon: Icons.class_outlined,
            iconColor: AppColors.primaryBlue,
            title: 'Manage Classes',
            subtitle: 'View and manage your classes',
            onTap: () {
              context.goNamed(RouteNames.tutorClasses);
            },
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.people_outline,
            iconColor: AppColors.accentTeal,
            title: 'Student Management',
            subtitle: 'Manage student enrollments and progress',
            onTap: () {
              context.goNamed(RouteNames.tutorStudents);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentManagementCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
      child: Column(
        children: [
          Builder(
            builder: (context) {
              try {
                return BlocBuilder<PaymentInfoBloc, PaymentInfoState>(
                  builder: (context, paymentState) {
                    String subtitle = 'Set up payment methods for students';
                    if (paymentState is PaymentInfoLoaded) {
                      final totalMethods =
                          paymentState.paymentInfo.bankAccounts.length +
                              paymentState.paymentInfo.eWallets.length +
                              paymentState.paymentInfo.otherMethods.length;
                      subtitle = totalMethods > 0
                          ? '$totalMethods payment method${totalMethods > 1 ? 's' : ''} configured'
                          : 'No payment methods configured';
                    }

                    return ProfileMenuItem(
                      icon: Icons.payment_outlined,
                      iconColor: AppColors.success,
                      title: 'Payment Information',
                      subtitle: subtitle,
                      onTap: () {
                        context.goNamed(RouteNames.tutorPaymentInfo);
                      },
                    );
                  },
                );
              } catch (e) {
                return ProfileMenuItem(
                  icon: Icons.payment_outlined,
                  iconColor: AppColors.textMedium,
                  title: 'Payment Information',
                  subtitle: 'Service unavailable',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Payment service is currently unavailable'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  },
                );
              }
            },
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.primaryBlue,
            title: 'Payment Records',
            subtitle: 'View student payment history',
            onTap: () {
              context.goNamed(RouteNames.tutorPayments);
            },
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.price_change_outlined,
            iconColor: AppColors.accentOrange,
            title: 'Subject Pricing',
            subtitle: 'Manage subject costs and pricing',
            onTap: () {
              context.goNamed(RouteNames.tutorSubjectCosts);
            },
          ),
        ],
      ),
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
            icon: Icons.support_agent_outlined,
            iconColor: AppColors.primaryBlue,
            title: 'Contact Support',
            subtitle: 'Get in touch with our support team',
            onTap: () {
              // Contact support
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
}
