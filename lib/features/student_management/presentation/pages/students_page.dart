// lib/features/student_management/presentation/pages/students_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/student_management/presentation/widgets/course_enrollment_bottom_sheet.dart';
import 'package:sizer/sizer.dart';
import '../bloc/student_management_bloc.dart';
import '../bloc/student_management_event.dart';
import '../bloc/student_management_state.dart';
import '../widgets/student_list_item.dart';
import '../../domain/entities/student.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({Key? key}) : super(key: key);

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isSearching = false;

  // Filter and Sort Variables
  int? _gradeFilter;
  String? _subjectFilter;
  String _sortBy = 'name'; // Default sorting by name
  bool _sortAscending = true;
  bool _showFilterPanel = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Load students when page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentManagementBloc>().add(LoadAllStudentsEvent());
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Filter and sort students based on criteria
  List<Student> _processStudents(List<Student> students) {
    // Apply filters
    var filteredStudents = students.where((student) {
      // Search filter
      bool matchesSearch = _searchQuery.isEmpty ||
          student.name.toLowerCase().contains(_searchQuery) ||
          student.studentId.toLowerCase().contains(_searchQuery) ||
          'grade ${student.grade}'.toLowerCase().contains(_searchQuery) ||
          (student.subjects?.any(
                  (subject) => subject.toLowerCase().contains(_searchQuery)) ??
              false);

      // Grade filter
      bool matchesGrade = _gradeFilter == null || student.grade == _gradeFilter;

      // Subject filter
      bool matchesSubject = _subjectFilter == null ||
          (student.subjects?.contains(_subjectFilter) ?? false);

      return matchesSearch && matchesGrade && matchesSubject;
    }).toList();

    // Apply sorting
    filteredStudents.sort((a, b) {
      int compareResult;

      switch (_sortBy) {
        case 'name':
          compareResult = a.name.compareTo(b.name);
          break;
        case 'grade':
          compareResult = a.grade.compareTo(b.grade);
          break;
        case 'id':
          compareResult = a.studentId.compareTo(b.studentId);
          break;
        default:
          compareResult = a.name.compareTo(b.name);
      }

      return _sortAscending ? compareResult : -compareResult;
    });

    return filteredStudents;
  }

  Future<void> _refreshStudents() async {
    setState(() {
      _isRefreshing = true;
    });

    context.read<StudentManagementBloc>().add(LoadAllStudentsEvent());

    // Add a small delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _isRefreshing = false;
    });
  }

  void _showQuickActionMenu(BuildContext context, Student student) {
    print('Student ID in list: ${student.documentId}');
    print('Student ID field: ${student.studentId}');
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 5.w,
                      backgroundColor: _getAvatarColor(student.name),
                      child: Text(
                        student.name.isNotEmpty
                            ? student.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                          Text(
                            'ID: ${student.studentId}',
                            style: TextStyle(
                              color: AppColors.textMedium,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 6.w),
              _buildActionTile(
                icon: Icons.person,
                title: 'View Profile',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/tutor/students/${student.studentId}',
                      extra: student);
                },
              ),
              _buildActionTile(
                icon: Icons.add_circle_outline,
                title: 'Add to Course',
                onTap: () {
                  Navigator.pop(context);
                  CourseEnrollmentBottomSheet.show(
                    context: context,
                    studentId: student.studentId,
                    studentName: student.name,
                  );
                },
              ),
              _buildActionTile(
                icon: Icons.calendar_today,
                title: 'View Attendance',
                onTap: () {},
              ),
              _buildActionTile(
                icon: Icons.task_alt,
                title: 'View Tasks',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue, size: 6.w),
      title: Text(title, style: TextStyle(fontSize: 14.sp)),
      onTap: onTap,
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students', style: TextStyle(fontSize: 18.sp)),
      ),
      body: Column(
        children: [
          // Manage Payments Card
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.w),
              ),
              elevation: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(3.w),
                onTap: () {
                  context.push('/tutor/payments', extra: {
                    'month': DateTime.now().month,
                    'year': DateTime.now().year,
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: 4.w, horizontal: 5.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.5.w),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(2.w),
                        ),
                        child: Icon(
                          Icons.payments_rounded,
                          color: AppColors.primaryBlue,
                          size: 6.5.w,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage Payments',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 1.w),
                            Text(
                              'View and update payment records',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.primaryBlue,
                        size: 6.w,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search and Filter Row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                // Search Field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      hintStyle: TextStyle(fontSize: 14.sp),
                      prefixIcon: Icon(Icons.search, size: 5.w),
                      filled: true,
                      fillColor: Colors.white,
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
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 3.w),
                    ),
                  ),
                ),

                // Filter Button
                IconButton(
                  icon: Icon(
                    _showFilterPanel
                        ? Icons.filter_list_off
                        : Icons.filter_list,
                    color: _showFilterPanel
                        ? AppColors.primaryBlue
                        : AppColors.textMedium,
                    size: 6.w,
                  ),
                  onPressed: () {
                    setState(() {
                      _showFilterPanel = !_showFilterPanel;
                    });
                  },
                  tooltip: _showFilterPanel ? 'Hide filters' : 'Show filters',
                  padding: EdgeInsets.all(3.w),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.w),

          // Filter Panel (expandable)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilterPanel ? 35.w : 0,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Filter & Sort',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        )),
                    SizedBox(height: 2.w),

                    // Filter Options
                    Row(
                      children: [
                        // Grade Filter
                        Expanded(
                          child: _buildDropdown<int?>(
                            label: 'Grade',
                            value: _gradeFilter,
                            items: [null, 1, 2, 3, 4, 5, 6].map((grade) {
                              return DropdownMenuItem<int?>(
                                value: grade,
                                child: Text(
                                  grade == null
                                      ? 'All Grades'
                                      : 'Grade $grade',
                                  style: TextStyle(fontSize: 13.sp),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _gradeFilter = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 3.w),

                        // Subject Filter
                        Expanded(
                          child: _buildDropdown<String?>(
                            label: 'Subject',
                            value: _subjectFilter,
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Subjects',
                                    style: TextStyle(fontSize: 13.sp)),
                              ),
                              ...[
                                'Mathematics',
                                'Science',
                                'English',
                                'Bahasa Malaysia',
                                'Chinese'
                              ]
                                  .map((subject) => DropdownMenuItem<String?>(
                                        value: subject,
                                        child: Text(subject,
                                            style: TextStyle(fontSize: 13.sp)),
                                      ))
                                  .toList()
                            ],
                            onChanged: (value) {
                              setState(() {
                                _subjectFilter = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 3.w),

                    // Sort Options
                    Row(
                      children: [
                        // Sort By
                        Expanded(
                          child: _buildDropdown<String>(
                            label: 'Sort By',
                            value: _sortBy,
                            items: [
                              DropdownMenuItem<String>(
                                value: 'name',
                                child: Text('Name',
                                    style: TextStyle(fontSize: 13.sp)),
                              ),
                              DropdownMenuItem<String>(
                                value: 'grade',
                                child: Text('Grade',
                                    style: TextStyle(fontSize: 13.sp)),
                              ),
                              DropdownMenuItem<String>(
                                value: 'id',
                                child: Text('Student ID',
                                    style: TextStyle(fontSize: 13.sp)),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _sortBy = value;
                                });
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 3.w),

                        // Sort Direction
                        Expanded(
                          child: Row(
                            children: [
                              Text('Order: ',
                                  style: TextStyle(fontSize: 12.sp)),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _sortAscending = !_sortAscending;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 3.w,
                                      vertical: 2.w,
                                    ),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: AppColors.divider),
                                      borderRadius: BorderRadius.circular(1.w),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _sortAscending ? 'A → Z' : 'Z → A',
                                          style: TextStyle(fontSize: 12.sp),
                                        ),
                                        Icon(
                                          _sortAscending
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          size: 4.w,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider when filter panel is shown
          if (_showFilterPanel) const Divider(height: 1),

          // Students List Area
          Expanded(
            child: BlocConsumer<StudentManagementBloc, StudentManagementState>(
              listener: (context, state) {
                if (state is StudentManagementError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.message,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is StudentManagementLoading &&
                    state is! AllStudentsLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AllStudentsLoaded) {
                  final filteredStudents = _processStudents(state.students);

                  if (filteredStudents.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshStudents,
                    child: Stack(
                      children: [
                        // Actual list
                        ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(4.w),
                          // Add key for better list diffing
                          key: ValueKey<String>(
                              'student_list_${filteredStudents.length}_$_sortBy'),
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            return Semantics(
                              label:
                                  'Student ${student.name}, Grade ${student.grade}',
                              child: StudentListItem(
                                student: student,
                                onTap: () {
                                  context.push(
                                      '/tutor/students/${student.documentId}');
                                },
                                onLongPress: () {
                                  _showQuickActionMenu(context, student);
                                },
                              ),
                            );
                          },
                        ),

                        // Refresh indicator overlay
                        if (_isRefreshing)
                          const Positioned.fill(
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Failed to load students',
                          style: TextStyle(fontSize: 16.sp)),
                      SizedBox(height: 4.w),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<StudentManagementBloc>()
                              .add(LoadAllStudentsEvent());
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 3.w),
                        ),
                        child: Text('Retry', style: TextStyle(fontSize: 14.sp)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    // Different empty states based on search/filter status
    if (_searchQuery.isNotEmpty ||
        _gradeFilter != null ||
        _subjectFilter != null) {
      // No results found after filtering
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 16.w,
              color: AppColors.textLight,
            ),
            SizedBox(height: 4.w),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No students found matching "$_searchQuery"'
                  : 'No students match the selected filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textMedium,
              ),
            ),
            SizedBox(height: 4.w),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _gradeFilter = null;
                  _subjectFilter = null;
                });
              },
              icon: Icon(Icons.clear, size: 5.w),
              label: Text('Clear Filters', style: TextStyle(fontSize: 14.sp)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.w),
              ),
            ),
          ],
        ),
      );
    } else {
      // No students at all
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 20.w,
              color: AppColors.textLight,
            ),
            SizedBox(height: 6.w),
            Text(
              'No Students Found',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 3.w),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Text(
                'Students who register for your courses will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 16.sp,
                ),
              ),
            ),
            SizedBox(height: 6.w),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/tutor/classes');
              },
              icon: Icon(Icons.add, size: 5.w),
              label: Text('Add New Student', style: TextStyle(fontSize: 14.sp)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.w,
                  vertical: 3.w,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textMedium,
          ),
        ),
        SizedBox(height: 1.w),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(1.w),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, size: 6.w),
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              borderRadius: BorderRadius.circular(1.w),
              items: items,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
      ],
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

    // Use a simple hash function to get a consistent color for the same name
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = (hash + name.codeUnitAt(i)) % colors.length;
    }

    return colors[hash];
  }
}
