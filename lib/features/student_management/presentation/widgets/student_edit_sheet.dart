import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/config/theme/app_colors.dart';
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
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 16.0 + MediaQuery.of(context).viewInsets.bottom,
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
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name field
          _buildTextField(
            controller: _nameController,
            label: 'Student Name',
            icon: Icons.person_outline,
            hint: 'Enter full name',
          ),
          const SizedBox(height: 16),

          // Phone field
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            hint: 'Enter phone number (optional)',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // Email field (read-only)
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            hint: 'Email address',
            readOnly: true,
            helperText: 'Email cannot be changed',
          ),
          const SizedBox(height: 16),

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
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      final grade = index + 1;
                      final isSelected = grade == _selectedGrade;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
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
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
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
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
            filled: true,
            fillColor: readOnly ? AppColors.backgroundLight : Colors.white,
            helperText: helperText,
            helperStyle: TextStyle(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
          style: TextStyle(
            color: readOnly ? AppColors.textMedium : AppColors.textDark,
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
