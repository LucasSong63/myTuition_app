import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:sizer/sizer.dart';
import '../bloc/student_management_bloc.dart';
import '../bloc/student_management_event.dart';
import '../bloc/student_management_state.dart';
import '../../domain/entities/student.dart';

class StudentEditSheet extends StatefulWidget {
  final Student student;

  const StudentEditSheet({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  State<StudentEditSheet> createState() => _StudentEditSheetState();
}

class _StudentEditSheetState extends State<StudentEditSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late int _selectedGrade;
  late List<String> _selectedSubjects;
  bool _isLoading = false;

  final List<String> _allSubjects = [
    'Mathematics',
    'Science',
    'English',
    'Bahasa Malaysia',
    'Chinese',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _phoneController = TextEditingController(text: widget.student.phone ?? '');
    _emailController = TextEditingController(text: widget.student.email);
    _selectedGrade = widget.student.grade;
    _selectedSubjects = widget.student.subjects?.toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _updateProfile() {
    setState(() {
      _isLoading = true;
    });

    final bloc = context.read<StudentManagementBloc>();

    // Only update fields that have changed
    bloc.add(
      UpdateStudentProfileEvent(
        userId: widget.student.documentId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        grade: _selectedGrade,
        subjects: _selectedSubjects,
      ),
    );

    // Close sheet after a short delay to allow animation
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 4.w,
        right: 4.w,
        top: 4.w,
        bottom: 4.w + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet header
          Row(
            children: [
              Text(
                'Edit Student Profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, size: 6.w),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
            ],
          ),
          SizedBox(height: 4.w),

          // Name field
          _buildTextField(
            controller: _nameController,
            label: 'Student Name',
            icon: Icons.person_outline,
            hint: 'Enter full name',
          ),
          SizedBox(height: 4.w),

          // Phone field
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            hint: 'Enter phone number (optional)',
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 4.w),

          // Email field (read-only)
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            hint: 'Email address',
            readOnly: true,
            helperText: 'Email cannot be changed',
          ),
          SizedBox(height: 4.w),

          // Grade selector
          Semantics(
            label: 'Select grade level',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grade Level',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 2.w),
                SizedBox(
                  height: 12.w,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      final grade = index + 1;
                      final isSelected = grade == _selectedGrade;
                      return Padding(
                        padding: EdgeInsets.only(right: 2.w),
                        child: ChoiceChip(
                          label: Text('Grade $grade'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedGrade = grade;
                              });
                            }
                          },
                          backgroundColor: AppColors.backgroundLight,
                          selectedColor: AppColors.primaryBlueLight,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primaryBlueDark
                                : AppColors.textMedium,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12.sp,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 3.w),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.w),

          // Subject selector
          Semantics(
            label: 'Select preferred subjects',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferred Subjects',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 2.w),
                Wrap(
                  spacing: 2.w,
                  runSpacing: 2.w,
                  children: _allSubjects.map((subject) {
                    final isSelected = _selectedSubjects.contains(subject);
                    return FilterChip(
                      label: Text(subject),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSubjects.add(subject);
                          } else {
                            _selectedSubjects.remove(subject);
                          }
                        });
                      },
                      backgroundColor:
                          _getSubjectColor(subject).withOpacity(0.1),
                      selectedColor: _getSubjectColor(subject).withOpacity(0.2),
                      checkmarkColor: _getSubjectColor(subject),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? _getSubjectColor(subject)
                            : AppColors.textMedium,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12.sp,
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.w),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 12.w,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 6.w,
                      height: 6.w,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 0.5.w,
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 2.w),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 2.w),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          inputFormatters: keyboardType == TextInputType.phone
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ]
              : null,
          validator: keyboardType == TextInputType.phone
              ? (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 6) {
                      return 'Phone number must be at least 6 digits';
                    }
                  }
                  return null;
                }
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13.sp),
            prefixIcon: Icon(icon, size: 5.w),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
              borderSide:
                  BorderSide(color: AppColors.primaryBlue, width: 0.5.w),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
              borderSide: BorderSide(color: AppColors.error),
            ),
            filled: true,
            fillColor: readOnly ? AppColors.backgroundLight : Colors.white,
            helperText: helperText,
            helperStyle: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textMedium,
            ),
            errorStyle: TextStyle(
              fontSize: 10.sp,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 3.w,
            ),
          ),
          style: TextStyle(
            color: readOnly ? AppColors.textMedium : AppColors.textDark,
            fontSize: 15.sp,
          ),
        ),
      ],
    );
  }

  Color _getSubjectColor(String subject) {
    subject = subject.toLowerCase();
    if (subject.contains('math')) return AppColors.mathSubject;
    if (subject.contains('science')) return AppColors.scienceSubject;
    if (subject.contains('english')) return AppColors.englishSubject;
    if (subject.contains('bahasa')) return AppColors.bahasaSubject;
    if (subject.contains('chinese')) return AppColors.chineseSubject;
    return AppColors.primaryBlue;
  }
}
