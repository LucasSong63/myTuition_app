import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/router/route_names.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/course.dart';
import '../bloc/course_bloc.dart';
import '../bloc/course_event.dart';
import '../bloc/course_state.dart';

class TutorCoursesPage extends StatefulWidget {
  const TutorCoursesPage({Key? key}) : super(key: key);

  @override
  State<TutorCoursesPage> createState() => _TutorCoursesPageState();
}

class _TutorCoursesPageState extends State<TutorCoursesPage> {
  @override
  void initState() {
    super.initState();
    // Schedule the loading after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourses();
    });
  }

  void _loadCourses() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      String tutorId = authState.user.id;
      if (tutorId.isNotEmpty) {
        context.read<CourseBloc>().add(
              LoadTutorCoursesEvent(tutorId: tutorId),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get tutor ID from auth state
    final authState = context.read<AuthBloc>().state;
    String tutorId = '';
    if (authState is Authenticated) {
      tutorId = authState.user.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Reload the courses when the user pulls down
          _loadCourses();
          // Wait a short time to ensure the refresh indicator is shown
          return await Future.delayed(const Duration(milliseconds: 800));
        },
        child: BlocBuilder<CourseBloc, CourseState>(
          builder: (context, state) {
            // Loading state
            if (state is CourseLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Loaded state
            if (state is CoursesLoaded) {
              final courses = state.courses;

              if (courses.isEmpty) {
                return _buildEmptyState();
              }

              // Group courses by grade
              final Map<int, List<Course>> coursesByGrade = {};
              for (var course in courses) {
                if (!coursesByGrade.containsKey(course.grade)) {
                  coursesByGrade[course.grade] = [];
                }
                coursesByGrade[course.grade]!.add(course);
              }

              // Sort grades
              final sortedGrades = coursesByGrade.keys.toList()..sort();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedGrades.length,
                itemBuilder: (context, index) {
                  final grade = sortedGrades[index];
                  final gradeCourses = coursesByGrade[grade]!;

                  return _buildGradeSection(context, grade, gradeCourses);
                },
              );
            }

            // Error or other states - The RefreshIndicator will still work here
            return RefreshIndicator(
              onRefresh: () async {
                _loadCourses();
                // Add a delay to show the refresh indicator
                return await Future.delayed(const Duration(milliseconds: 800));
              },
              child: ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height / 3),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load courses',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCourses,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add new course/class
          // context.push('/tutor/classes/new');
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Class',
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height / 3),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.class_outlined,
                size: 64,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 16),
              const Text(
                'No classes found',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first class',
                style: TextStyle(
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradeSection(
      BuildContext context, int grade, List<Course> courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Grade $grade',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...courses.map((course) => _buildCourseCard(context, course)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Important: Use the actual ID from the course entity, not a derived string
          context.pushNamed(RouteNames.tutorCourseDetails,
              pathParameters: {'courseId': course.id});

          // Debug information to help troubleshoot
          print('Navigating to course with ID: ${course.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 50,
                decoration: BoxDecoration(
                  color: _getSubjectColor(course.subject),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.subject,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Add status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: course.isActive
                                ? AppColors.success.withOpacity(0.2)
                                : AppColors.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            course.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 12,
                              color: course.isActive
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Grade ${course.grade}',
                      style: TextStyle(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return AppColors.mathSubject;
      case 'science':
        return AppColors.scienceSubject;
      case 'english':
        return AppColors.englishSubject;
      case 'bahasa malaysia':
        return AppColors.bahasaSubject;
      case 'chinese':
        return AppColors.chineseSubject;
      default:
        return AppColors.primaryBlue;
    }
  }
}
