import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/student_management/presentation/widgets/course_enrollment_bottom_sheet.dart';
import '../bloc/student_management_bloc.dart';
import '../bloc/student_management_event.dart';
import '../bloc/student_management_state.dart';
import '../../domain/entities/student.dart';

class StudentDetailPage extends StatefulWidget {
  final String studentId;

  const StudentDetailPage({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Student? _student;
  bool _dialogIsOpen = false;
  StudentManagementBloc? _dialogBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load student details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentManagementBloc>().add(
            LoadStudentDetailsEvent(studentId: widget.studentId),
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dialogBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Courses'),
          ],
        ),
      ),
      body: BlocConsumer<StudentManagementBloc, StudentManagementState>(
        listener: (context, state) {
          if (state is StudentDetailsLoaded) {
            setState(() {
              _student = state.student;
            });
          }

          if (state is StudentManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }

          if (state is StudentManagementActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );

            // Refresh data after successful action
            if (_student != null) {
              context.read<StudentManagementBloc>().add(
                    LoadEnrolledCoursesEvent(studentId: _student!.studentId),
                  );
            }
          }
        },
        builder: (context, state) {
          if (state is StudentManagementLoading && _student == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_student == null) {
            return const Center(
              child: Text('Student not found'),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Profile Tab
              _buildProfileTab(context, _student!),

              // Courses Tab
              _buildCoursesTab(context, _student!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, Student student) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student overview card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile picture
                  _buildProfilePicture(student),
                  const SizedBox(height: 16),

                  // Student name and ID
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${student.studentId}',
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Basic Information Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Basic Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Email', student.email),
                  _buildInfoRow('Phone', student.phone ?? 'Not provided'),
                  _buildInfoRow('Grade', 'Grade ${student.grade}'),
                  _buildInfoRow(
                    'Email Verified',
                    student.emailVerified ? 'Yes' : 'No',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Preferred Subjects Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preferred Subjects',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (student.subjects != null && student.subjects!.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: student.subjects!.map((subject) {
                        return Chip(
                          label: Text(subject),
                          backgroundColor:
                              _getSubjectColor(subject).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _getSubjectColor(subject),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Text(
                      'No preferred subjects specified',
                      style: TextStyle(
                        color: AppColors.textMedium,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Payment Management Card (Placeholder)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment management coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Manage Payments'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesTab(BuildContext context, Student student) {
    return BlocBuilder<StudentManagementBloc, StudentManagementState>(
      builder: (context, state) {
        // Check if we have enrolled courses loaded
        List<Map<String, dynamic>> enrolledCourses = [];

        if (state is EnrolledCoursesLoaded &&
            state.studentId == student.studentId) {
          enrolledCourses = state.enrolledCourses;
        } else {
          // If not loaded yet, trigger the loading
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<StudentManagementBloc>().add(
                  LoadEnrolledCoursesEvent(studentId: student.studentId),
                );
          });
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<StudentManagementBloc>().add(
                  LoadEnrolledCoursesEvent(studentId: student.studentId),
                );
            return Future.delayed(const Duration(milliseconds: 1000));
          },
          child: Column(
            children: [
              // Add to Course Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () => _showEnrollmentBottomSheet(context, student),
                  icon: const Icon(Icons.add),
                  label: const Text('Add to Course'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              // Courses List
              Expanded(
                child: state is StudentManagementLoading &&
                        enrolledCourses.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : enrolledCourses.isEmpty
                        ? _buildEmptyCoursesView()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: enrolledCourses.length,
                            itemBuilder: (context, index) {
                              final course = enrolledCourses[index];
                              return _buildCourseCard(
                                  context, course, student.studentId);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyCoursesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Enrolled Courses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add this student to a course',
            style: TextStyle(
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(
      BuildContext context, Map<String, dynamic> course, String studentId) {
    // Extract capacity information if available
    final int capacity = course['capacity'] ?? 20;
    final int currentEnrollment = course['currentEnrollment'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getSubjectColor(course['subject']),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['subject'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Grade ${course['grade']}',
                        style: TextStyle(
                          color: AppColors.textMedium,
                        ),
                      ),
                      // Add capacity info
                      const SizedBox(height: 4),
                      Text(
                        'Enrollment: $currentEnrollment/$capacity',
                        style: TextStyle(
                          color: currentEnrollment >= capacity
                              ? AppColors.error
                              : AppColors.success,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmRemoveFromCourse(
                      context, course['id'], course['subject'], studentId),
                ),
              ],
            ),
            if (course['tutorName'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Tutor: ${course['tutorName']}',
                  style: TextStyle(
                    color: AppColors.textMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture(Student student) {
    if (student.profilePictureUrl != null &&
        student.profilePictureUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: CachedNetworkImageProvider(
          student.profilePictureUrl!,
        ),
      );
    }

    // Default profile picture with first letter of name
    return CircleAvatar(
      radius: 50,
      backgroundColor: _getAvatarColor(student.name),
      child: Text(
        student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showEnrollmentBottomSheet(BuildContext context, Student student) {
    // Prevent opening multiple dialogs
    if (_dialogIsOpen) return;
    _dialogIsOpen = true;

    // Show the bottom sheet
    CourseEnrollmentBottomSheet.show(
      context: context,
      studentId: student.studentId,
      studentName: student.name,
    ).then((_) {
      // When bottom sheet closes
      _dialogIsOpen = false;

      // No need to manually refresh here since the same bloc instance is used
      // and the CourseEnrollmentBottomSheet already triggers the reload
    });
  }

  void _confirmRemoveFromCourse(BuildContext context, String courseId,
      String courseName, String studentId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove from Course'),
        content: Text(
            'Are you sure you want to remove this student from "$courseName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<StudentManagementBloc>().add(
                    RemoveStudentFromCourseEvent(
                      studentId: studentId,
                      courseId: courseId,
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
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
