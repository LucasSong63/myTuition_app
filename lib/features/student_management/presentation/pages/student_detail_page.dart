import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/student_management/presentation/widgets/course_enrollment_bottom_sheet.dart';
import 'package:mytuition/features/student_management/presentation/widgets/student_edit_sheet.dart';
import 'package:sizer/sizer.dart';
import '../bloc/student_management_bloc.dart';
import '../bloc/student_management_event.dart';
import '../bloc/student_management_state.dart';
import '../../domain/entities/student.dart';

class StudentDetailPage extends StatefulWidget {
  final String studentId;
  final Student? initialStudent;

  const StudentDetailPage({
    Key? key,
    required this.studentId,
    this.initialStudent,
  }) : super(key: key);

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Student? _student;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  // Define a consistent scroll physics to use across all ScrollViews
  final ScrollPhysics _scrollPhysics = const AlwaysScrollableScrollPhysics(
    parent: BouncingScrollPhysics(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _student = widget.initialStudent;

    // Add scroll listener to control app bar title visibility
    _scrollController.addListener(() {
      setState(() {
        _showTitle = _scrollController.offset > 120;
      });
    });

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
    _scrollController.dispose();
    super.dispose();
  }

  void _showEditProfileSheet(BuildContext context, Student student) {
    // Get the bloc from the current context before showing the modal
    final bloc = context.read<StudentManagementBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        // Provide the existing bloc to the bottom sheet
        return BlocProvider.value(
          value: bloc,
          child: StudentEditSheet(student: student),
        );
      },
    ).then((_) {
      // Refresh student details when edit sheet closes
      bloc.add(LoadStudentDetailsEvent(studentId: student.studentId));
    });
  }

  void _confirmRemoveFromCourse(BuildContext context, String courseId,
      String courseName, String studentId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.w),
        ),
        title: Text(
          'Remove from Course',
          style: TextStyle(fontSize: 16.sp),
        ),
        content: Text(
          'Are you sure you want to remove this student from "$courseName"?',
          style: TextStyle(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 13.sp),
            ),
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            child: Text(
              'Remove',
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StudentManagementBloc, StudentManagementState>(
      listener: (context, state) {
        if (state is StudentDetailsLoaded) {
          setState(() {
            _student = state.student;
          });
        }

        if (state is StudentManagementError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: TextStyle(fontSize: 13.sp),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }

        if (state is StudentManagementActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: TextStyle(fontSize: 13.sp),
              ),
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_student == null) {
          return Scaffold(
            body: Center(
              child: Text(
                'Student not found',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          );
        }

        // Building the main UI with student data using NestedScrollView
        return Scaffold(
          key: _scaffoldKey,
          body: NestedScrollView(
            controller: _scrollController,
            physics: _scrollPhysics,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 55.w,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.primaryBlue,
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _showTitle ? 1.0 : 0.0,
                    child: Text(_student!.name),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: AppColors.primaryBlue,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 3.w),
                          // Profile picture with hero animation
                          Hero(
                            tag: 'student_avatar_${_student!.studentId}',
                            child:
                                _buildProfilePicture(_student!, radius: 12.w),
                          ),
                          SizedBox(height: 3.w),

                          // Student name
                          Text(
                            _student!.name,
                            style: TextStyle(
                              fontSize: 19.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          // Student ID
                          Text(
                            'ID: ${_student!.studentId}',
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: Colors.white70,
                            ),
                          ),

                          SizedBox(height: 2.w),

                          // Grade pill
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.5.w,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(4.w),
                            ),
                            child: Text(
                              'Grade ${_student!.grade}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primaryBlue,
                      unselectedLabelColor: AppColors.textMedium,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicatorColor: AppColors.primaryBlue,
                      indicator: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.primaryBlue,
                            width: 0.8.w,
                          ),
                        ),
                      ),
                      tabs: [
                        Tab(
                          icon: Icon(Icons.person_outline, size: 5.w),
                          text: 'Profile',
                        ),
                        Tab(
                          icon: Icon(Icons.school_outlined, size: 5.w),
                          text: 'Courses',
                        ),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Profile Tab
                _buildProfileTab(context, _student!),

                // Courses Tab
                _buildCoursesTab(context, _student!),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showEditProfileSheet(context, _student!),
            backgroundColor: AppColors.primaryBlue,
            tooltip: 'Edit Profile',
            child: const Icon(Icons.edit),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(BuildContext context, Student student) {
    return Semantics(
      label: 'Student profile information for ${student.name}',
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<StudentManagementBloc>().add(
                LoadStudentDetailsEvent(studentId: student.studentId),
              );
          return Future.delayed(const Duration(milliseconds: 1000));
        },
        child: ListView(
          physics: _scrollPhysics,
          padding: EdgeInsets.all(4.w),
          children: [
            // Contact Information Card
            _buildSectionCard(
              title: 'Contact Information',
              icon: Icons.contact_mail_outlined,
              iconColor: AppColors.primaryBlue,
              children: [
                _buildInfoItem(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: student.email,
                  semantic: 'Student email is ${student.email}',
                ),
                if (student.phone != null && student.phone!.isNotEmpty)
                  _buildInfoItem(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: student.phone!,
                    semantic: 'Student phone number is ${student.phone}',
                  ),
                _buildInfoItem(
                  icon: Icons.verified_outlined,
                  label: 'Email Verified',
                  value: student.emailVerified ? 'Yes' : 'No',
                  valueColor: student.emailVerified
                      ? AppColors.success
                      : AppColors.error,
                  semantic:
                      'Email verification status is ${student.emailVerified ? "verified" : "not verified"}',
                ),
              ],
            ),

            SizedBox(height: 4.w),

            // Academic Information Card
            _buildSectionCard(
              title: 'Academic Information',
              icon: Icons.school_outlined,
              iconColor: AppColors.accentTeal,
              children: [
                _buildInfoItem(
                  icon: Icons.grade_outlined,
                  label: 'Grade Level',
                  value: 'Grade ${student.grade}',
                  valueColor: _getGradeColor(student.grade),
                  semantic: 'Student is in Grade ${student.grade}',
                ),
                _buildInfoItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Joined On',
                  value: _formatDate(student.createdAt),
                  semantic:
                      'Student joined on ${_formatDate(student.createdAt)}',
                ),
                if (student.subjects != null && student.subjects!.isNotEmpty)
                  _buildSubjectsList(student.subjects!),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
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

        return Semantics(
          label: 'Courses tab for ${student.name}',
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<StudentManagementBloc>().add(
                    LoadEnrolledCoursesEvent(studentId: student.studentId),
                  );
              return Future.delayed(const Duration(milliseconds: 1000));
            },
            child: enrolledCourses.isEmpty && state is StudentManagementLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Add to Course Button
                      Padding(
                        padding: EdgeInsets.all(4.w),
                        child: ElevatedButton.icon(
                          onPressed: () => CourseEnrollmentBottomSheet.show(
                            context: context,
                            studentId: student.studentId,
                            studentName: student.name,
                          ),
                          icon: Icon(Icons.add, size: 5.w),
                          label: Text(
                            'Add to Course',
                            style: TextStyle(fontSize: 15.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 12.w),
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2.w),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),

                      // Courses List or Empty State
                      Expanded(
                        child: enrolledCourses.isEmpty
                            ? _buildEmptyCoursesView()
                            : ListView.builder(
                                physics: _scrollPhysics,
                                padding: const EdgeInsets.all(16),
                                itemCount: enrolledCourses.length,
                                itemBuilder: (context, index) {
                                  final course = enrolledCourses[index];
                                  return _buildEnhancedCourseCard(
                                    context,
                                    course,
                                    student.studentId,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectsList(List<String> subjects) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.subject_outlined,
                  size: 20,
                  color: AppColors.textMedium,
                ),
                const SizedBox(width: 8),
                Text(
                  'Preferred Subjects',
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subjects.map((subject) {
              return Chip(
                label: Text(subject),
                backgroundColor: _getSubjectColor(subject).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _getSubjectColor(subject),
                  fontWeight: FontWeight.w500,
                ),
                padding: const EdgeInsets.all(4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCoursesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_outlined,
              size: 16.w,
              color: AppColors.primaryBlue.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 6.w),
          Text(
            'No Enrolled Courses',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 3.w),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Text(
              'This student is not enrolled in any courses yet. Use the button above to add them to a course.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMedium,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCourseCard(
    BuildContext context,
    Map<String, dynamic> course,
    String studentId,
  ) {
    final int capacity = course['capacity'] ?? 20;
    final int currentEnrollment = course['currentEnrollment'] ?? 0;
    final double enrollmentPercentage = currentEnrollment / capacity;
    final Color subjectColor = _getSubjectColor(course['subject']);

    return Semantics(
      label: 'Course ${course['subject']} for Grade ${course['grade']}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course header with color bar
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: subjectColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with subject and remove button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: subjectColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getSubjectIcon(course['subject']),
                          color: subjectColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course['subject'],
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Grade ${course['grade']}',
                              style: TextStyle(
                                color: AppColors.textMedium,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 6.w,
                        ),
                        tooltip: 'Remove from course',
                        onPressed: () => _confirmRemoveFromCourse(
                          context,
                          course['id'],
                          course['subject'],
                          studentId,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 3.w),

                  // Capacity indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Class Capacity',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMedium,
                              fontSize: 14.sp,
                            ),
                          ),
                          Text(
                            '$currentEnrollment/$capacity students',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: enrollmentPercentage >= 0.9
                                  ? AppColors.error
                                  : enrollmentPercentage >= 0.7
                                      ? AppColors.warning
                                      : AppColors.success,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.5.w),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(1.w),
                        child: LinearProgressIndicator(
                          value: enrollmentPercentage,
                          backgroundColor: AppColors.backgroundDark,
                          color: enrollmentPercentage >= 0.9
                              ? AppColors.error
                              : enrollmentPercentage >= 0.7
                                  ? AppColors.warning
                                  : AppColors.success,
                          minHeight: 1.5.w,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Tutor information
                  if (course['tutorName'] != null &&
                      course['tutorName'].isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 4.w,
                          color: AppColors.textMedium,
                        ),
                        SizedBox(width: 1.5.w),
                        Text(
                          'Tutor: ',
                          style: TextStyle(
                            color: AppColors.textMedium,
                            fontSize: 14.sp,
                          ),
                        ),
                        Text(
                          course['tutorName'],
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
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
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    String? semantic,
  }) {
    return Semantics(
      label: semantic ?? '$label is $value',
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 5.w,
              color: AppColors.textMedium,
            ),
            SizedBox(width: 2.w),
            SizedBox(
              width: 25.w,
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppColors.textDark,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 6.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.w),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture(Student student, {double radius = 12.0}) {
    if (student.profilePictureUrl != null &&
        student.profilePictureUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(student.profilePictureUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          // This is where you handle the error
          print('Error loading profile image for ${student.name}: $exception');
          // Optionally, you could set a flag here to show a different fallback
          // in the UI if needed, though CircleAvatar already handles fallbacks gracefully.
        },
        child: (student.profilePictureUrl == null ||
                student.profilePictureUrl!.isEmpty)
            ? _buildFallbackAvatar(student,
                radius) // Shown if URL is bad from the start or if image fails and child is needed
            : null, // No child if backgroundImage is expected to load
      );
    }

    // Default profile picture with first letter of name (fallback)
    return _buildFallbackAvatar(student, radius);
  }

// Helper for the fallback avatar content
  Widget _buildFallbackAvatar(Student student, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _getAvatarColor(student.name),
      child: Text(
        student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
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

  Color _getGradeColor(int grade) {
    switch (grade) {
      case 1:
      case 2:
        return AppColors.accentTealLight;
      case 3:
      case 4:
        return AppColors.accentTeal;
      case 5:
      case 6:
        return AppColors.accentTealDark;
      default:
        return AppColors.accentTeal;
    }
  }

  IconData _getSubjectIcon(String subject) {
    subject = subject.toLowerCase();
    if (subject.contains('math')) return Icons.calculate_outlined;
    if (subject.contains('science')) return Icons.science_outlined;
    if (subject.contains('english')) return Icons.abc_outlined;
    if (subject.contains('bahasa')) return Icons.language_outlined;
    if (subject.contains('chinese')) return Icons.translate_outlined;
    return Icons.book_outlined;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    final difference = dateToCheck.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference == 1) {
      return 'Tomorrow';
    }

    // Format as Month Day, Year
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// SliverPersistentHeaderDelegate for TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return true; // This ensures the delegate rebuilds if the TabBar changes
  }
}
