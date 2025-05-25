import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/domain/entities/user.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_event.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_event.dart';
import 'package:mytuition/features/profile/presentation/bloc/profile_state.dart';

class TutorProfilePage extends StatefulWidget {
  const TutorProfilePage({Key? key}) : super(key: key);

  @override
  State<TutorProfilePage> createState() => _TutorProfilePageState();
}

class _TutorProfilePageState extends State<TutorProfilePage> {
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
                      _buildPersonalInfoSection(user),
                      const SizedBox(height: 16),
                      _buildTeachingInfoSection(user),
                      const SizedBox(height: 16),
                      _buildQuickActionsSection(),
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
          const SizedBox(height: 8),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.school,
                  color: AppColors.accentOrange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tutor',
                  style: TextStyle(
                    color: AppColors.accentOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildTeachingInfoSection(User user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teaching Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Teaching subjects
            const Text(
              'Teaching Subjects:',
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
                    backgroundColor: AppColors.accentOrange.withOpacity(0.2),
                    labelStyle: TextStyle(color: AppColors.accentOrange),
                  );
                }).toList(),
              )
            else
              Text(
                'No subjects assigned',
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

  Widget _buildQuickActionsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildQuickActionTile(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan QR Codes',
                  color: AppColors.accentTeal,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Go to any course to scan QR codes for attendance'),
                      ),
                    );
                  },
                ),
                _buildQuickActionTile(
                  icon: Icons.analytics,
                  label: 'View Reports',
                  color: AppColors.primaryBlue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reports feature coming soon!'),
                      ),
                    );
                  },
                ),
                _buildQuickActionTile(
                  icon: Icons.notifications,
                  label: 'Notifications',
                  color: AppColors.accentOrange,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification center coming soon!'),
                      ),
                    );
                  },
                ),
                _buildQuickActionTile(
                  icon: Icons.settings,
                  label: 'Settings',
                  color: AppColors.textMedium,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings page coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
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

  // Image picker methods (same as student profile)
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
