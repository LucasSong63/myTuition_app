import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mytuition/config/theme/app_colors.dart';
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
  String _searchQuery = '';
  bool _isSearching = false;

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
    super.dispose();
  }

  // Filter students based on search query
  List<Student> _filterStudents(List<Student> students) {
    if (_searchQuery.isEmpty) {
      return students;
    }
    return students.where((student) {
      return student.name.toLowerCase().contains(_searchQuery) ||
          student.studentId.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                autofocus: true,
              )
            : const Text('Students'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: BlocConsumer<StudentManagementBloc, StudentManagementState>(
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
            final filteredStudents = _filterStudents(state.students);

            if (filteredStudents.isEmpty) {
              return Center(
                child: _searchQuery.isNotEmpty
                    ? Text('No students found matching "$_searchQuery"')
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No students found',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Students who register will appear here',
                            style: TextStyle(color: AppColors.textMedium),
                          ),
                        ],
                      ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<StudentManagementBloc>()
                    .add(LoadAllStudentsEvent());
                return Future.delayed(const Duration(milliseconds: 1000));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  return StudentListItem(
                    student: student,
                    onTap: () {
                      // Navigate to student details page
                      context.push('/tutor/students/${student.id}');
                    },
                  );
                },
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
    );
  }
}
