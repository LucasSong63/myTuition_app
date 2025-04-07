import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mytuition/features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/schedule.dart';
import '../bloc/course_bloc.dart';
import '../bloc/course_event.dart';
import '../bloc/course_state.dart';

class UpcomingSchedulesWidget extends StatelessWidget {
  const UpcomingSchedulesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Get user ID from auth state
    final authState = context.read<AuthBloc>().state;
    String userId = '';
    if (authState is Authenticated) {
      userId = authState.user.id;
    }

    return BlocBuilder<CourseBloc, CourseState>(
      builder: (context, state) {
        // Load schedules if not already loaded
        if (state is CourseInitial && userId.isNotEmpty) {
          context.read<CourseBloc>().add(
                LoadUpcomingSchedulesEvent(studentId: userId),
              );
          return const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is CourseLoading) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is SchedulesLoaded) {
          if (state.schedules.isEmpty) {
            return SizedBox(
              height: 100,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 32,
                      color: AppColors.textMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No upcoming classes',
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

          // Group by day
          final groupedSchedules = _groupSchedulesByDay(state.schedules);

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: groupedSchedules.length,
            itemBuilder: (context, index) {
              final day = groupedSchedules.keys.elementAt(index);
              final daySchedules = groupedSchedules[day]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: daySchedules.length,
                    itemBuilder: (context, idx) {
                      return _buildScheduleItem(context, daySchedules[idx]);
                    },
                  ),
                ],
              );
            },
          );
        }

        if (state is CourseError) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading schedules: ${state.message}',
                    style: TextStyle(
                      color: AppColors.error,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (userId.isNotEmpty) {
                        context.read<CourseBloc>().add(
                              LoadUpcomingSchedulesEvent(studentId: userId),
                            );
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Default state
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildScheduleItem(BuildContext context, Schedule schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: _getSubjectColor(schedule.subject),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${schedule.subject} (Grade ${schedule.grade})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schedule.location,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
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

  Map<String, List<Schedule>> _groupSchedulesByDay(List<Schedule> schedules) {
    final Map<String, List<Schedule>> grouped = {};

    for (var schedule in schedules) {
      if (!grouped.containsKey(schedule.day)) {
        grouped[schedule.day] = [];
      }

      grouped[schedule.day]!.add(schedule);
    }

    return grouped;
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
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
