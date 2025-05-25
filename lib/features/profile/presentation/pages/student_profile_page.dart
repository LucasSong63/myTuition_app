import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/domain/entities/user.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_event.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_event.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_state.dart';
import 'package:mytuition/core/utils/student_id_validator.dart';
import 'package:sizer/sizer.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({Key? key}) : super(key: key);

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          setState(() {
            _isEditing = false;
          });

          // Refresh auth state to reflect updated profile
          context.read<AuthBloc>().add(CheckAuthStatusEvent());
        }

        if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          actions: [
            // Edit/Save button
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                return IconButton(
                  icon: state is ProfileLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(_isEditing ? Icons.save : Icons.edit),
                  onPressed: state is ProfileLoading
                      ? null
                      : () {
                          if (_isEditing) {
                            // Save profile changes
                            if (_formKey.currentState!.validate()) {
                              final authState = context.read<AuthBloc>().state;
                              if (authState is Authenticated) {
                                context
                                    .read<ProfileBloc>()
                                    .add(UpdateProfileEvent(
                                      userId: authState.user.docId,
                                      name: _nameController.text.trim(),
                                      phone: _phoneController.text.trim(),
                                    ));
                              }
                            }
                          } else {
                            // Enter edit mode
                            setState(() {
                              _isEditing = true;
                            });
                          }
                        },
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              final user = state.user;

              // Initialize controllers when entering edit mode
              if (_isEditing && _nameController.text.isEmpty) {
                _nameController.text = user.name;
                _phoneController.text = user.phone ?? '';
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(user),
                      const SizedBox(height: 24),
                      _buildStudentIdSection(user),
                      const SizedBox(height: 16),
                      _buildQRCodeSection(user),
                      const SizedBox(height: 16),
                      _buildPersonalInfoSection(user),
                      const SizedBox(height: 16),
                      _buildAcademicInfoSection(user),
                    ],
                  ),
                ),
              );
            }

            // Loading state
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Center(
      child: Column(
        children: [
          // Profile picture with edit capability
          Stack(
            children: [
              // Profile image
              GestureDetector(
                onTap: _isEditing ? _showImagePickerOptions : null,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryBlueLight,
                  backgroundImage: user.profilePictureUrl != null
                      ? CachedNetworkImageProvider(user.profilePictureUrl!)
                      : null,
                  child: user.profilePictureUrl == null
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              // Edit icon overlay
              if (_isEditing)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // User name
          _isEditing
              ? TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                )
              : Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          // Email (non-editable)
          Text(
            user.email,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentIdSection(User user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Student ID',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user.studentId != null)
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy ID',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: user.studentId!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Student ID copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (user.studentId != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlueLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.badge,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      user.studentId!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Display year batch information
              _buildStudentBatchInfo(user.studentId!),
            ] else
              Text(
                'Not assigned',
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentBatchInfo(String studentId) {
    final year = StudentIdValidator.extractYear(studentId);
    final studentNumber = StudentIdValidator.extractStudentNumber(studentId);

    if (year == null || studentNumber == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.accentTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school,
            color: AppColors.accentTeal,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Class of $year • Student #$studentNumber',
            style: TextStyle(
              color: AppColors.accentTeal,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection(User user) {
    if (user.studentId == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My QR Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'share':
                        _shareQRCode(user.studentId!);
                        break;
                      case 'fullscreen':
                        _showFullScreenQR(user.studentId!);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'fullscreen',
                      child: Row(
                        children: [
                          Icon(Icons.fullscreen),
                          SizedBox(width: 8),
                          Text('View Full Screen'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share),
                          SizedBox(width: 8),
                          Text('Share QR Code'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: QrImageView(
                      data: user.studentId!,
                      // Static QR code with just student ID
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Instructions
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Show this QR code to your tutor for attendance',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap the menu for more options',
                          style: TextStyle(
                            color: AppColors.textMedium,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(User user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Phone number
            _buildInfoItem(
              'Phone',
              isEditing: _isEditing,
              value: user.phone ?? 'Not provided',
              editWidget: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixText: '+60 | ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  // Simple validation for Malaysian phone number
                  if (!RegExp(r'^[0-9]{9,10}$').hasMatch(value)) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicInfoSection(User user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Academic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Grade
            _buildInfoItem('Grade',
                value: 'Grade ${user.grade ?? "Not assigned"}'),
            const SizedBox(height: 16),
            // Subjects
            const Text(
              'Subjects:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (user.subjects != null && user.subjects!.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.subjects!.map((subject) {
                  return Chip(
                    label: Text(subject),
                    backgroundColor:
                        AppColors.primaryBlueLight.withOpacity(0.2),
                  );
                }).toList(),
              )
            else
              Text(
                'No subjects enrolled',
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    String label, {
    required String value,
    bool isEditing = false,
    Widget? editWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        if (isEditing && editWidget != null)
          editWidget
        else
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
      ],
    );
  }

  void _shareQRCode(String studentId) {
    // Implementation for sharing QR code
    // You can use share_plus package for this
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR code sharing functionality coming soon!'),
      ),
    );
  }

  void _showFullScreenQR(String studentId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenQRView(
          studentId: studentId,
          studentName: context.read<AuthBloc>().state is Authenticated
              ? (context.read<AuthBloc>().state as Authenticated).user.name
              : 'Student',
        ),
      ),
    );
  }

  // Image picker methods
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            if (context.read<AuthBloc>().state is Authenticated &&
                (context.read<AuthBloc>().state as Authenticated)
                        .user
                        .profilePictureUrl !=
                    null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  _removeProfilePicture();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          context.read<ProfileBloc>().add(UpdateProfilePictureEvent(
                userId: authState.user.docId,
                imageFile: imageFile,
              ));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  void _removeProfilePicture() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<ProfileBloc>().add(RemoveProfilePictureEvent(
            userId: authState.user.docId,
          ));
    }
  }
}

// Full screen QR code view
class _FullScreenQRView extends StatelessWidget {
  final String studentId;
  final String studentName;

  const _FullScreenQRView({
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My QR Code'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: 100.w,
            height: 80.h,
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 2.h),

                // Student info
                Text(
                  studentName,
                  style: TextStyle(
                    fontSize: 20.sp, // Responsive font size
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Text(
                  studentId,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textMedium,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),

                // Large QR Code - Responsive size
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: studentId,
                    version: QrVersions.auto,
                    size: 60.w,
                    // Responsive QR code size (60% of screen width)
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),

                SizedBox(height: 4.h),

                // Instructions - Flexible container
                Container(
                  width: 100.w,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryBlue,
                        size: 24.sp, // Responsive icon size
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Show this QR code to your tutor',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Make sure the code is clearly visible and well-lit for scanning',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 12.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 2.h), // Extra bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}
