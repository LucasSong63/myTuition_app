// lib/features/student_management/presentation/pages/students_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/student_management/presentation/widgets/course_enrollment_bottom_sheet.dart';
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _getAvatarColor(student.name),
                      child: Text(
                        student.name.isNotEmpty
                            ? student.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'ID: ${student.studentId}',
                            style: TextStyle(
                              color: AppColors.textMedium,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
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
      leading: Icon(icon, color: AppColors.primaryBlue),
      title: Text(title),
      onTap: onTap,
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
      ),
      body: Column(
        children: [
          // Manage Payments Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  context.push('/tutor/payments', extra: {
                    'month': DateTime.now().month,
                    'year': DateTime.now().year,
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.payments_rounded,
                          color: AppColors.primaryBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Manage Payments',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'View and update payment records',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search and Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Search Field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                  ),
                  onPressed: () {
                    setState(() {
                      _showFilterPanel = !_showFilterPanel;
                    });
                  },
                  tooltip: _showFilterPanel ? 'Hide filters' : 'Show filters',
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Filter Panel (expandable)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilterPanel ? 140 : 0,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filter & Sort',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

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
                                child: Text(grade == null
                                    ? 'All Grades'
                                    : 'Grade $grade'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _gradeFilter = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Subject Filter
                        Expanded(
                          child: _buildDropdown<String?>(
                            label: 'Subject',
                            value: _subjectFilter,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Subjects'),
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
                                        child: Text(subject),
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

                    const SizedBox(height: 12),

                    // Sort Options
                    Row(
                      children: [
                        // Sort By
                        Expanded(
                          child: _buildDropdown<String>(
                            label: 'Sort By',
                            value: _sortBy,
                            items: [
                              const DropdownMenuItem<String>(
                                value: 'name',
                                child: Text('Name'),
                              ),
                              const DropdownMenuItem<String>(
                                value: 'grade',
                                child: Text('Grade'),
                              ),
                              const DropdownMenuItem<String>(
                                value: 'id',
                                child: Text('Student ID'),
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
                        const SizedBox(width: 12),

                        // Sort Direction
                        Expanded(
                          child: Row(
                            children: [
                              const Text('Order: ',
                                  style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _sortAscending = !_sortAscending;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: AppColors.divider),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                            _sortAscending ? 'A → Z' : 'Z → A'),
                                        Icon(
                                          _sortAscending
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          size: 16,
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
                      content: Text(state.message),
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
                          padding: const EdgeInsets.all(16),
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
                      const Text('Failed to load students'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<StudentManagementBloc>()
                              .add(LoadAllStudentsEvent());
                        },
                        child: const Text('Retry'),
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
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No students found matching "$_searchQuery"'
                  : 'No students match the selected filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _gradeFilter = null;
                  _subjectFilter = null;
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
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
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 24),
            const Text(
              'No Students Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Students who register for your courses will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/tutor/classes');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Student'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
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
            fontSize: 12,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              borderRadius: BorderRadius.circular(4),
              items: items,
              onChanged: onChanged,
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
