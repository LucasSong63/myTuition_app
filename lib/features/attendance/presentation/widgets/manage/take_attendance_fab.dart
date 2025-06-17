// lib/features/attendance/presentation/widgets/manage/take_attendance_fab.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:mytuition/core/utils/navigation_utils.dart';
import '../../pages/take_attendance_page.dart';
import '../../bloc/attendance_bloc.dart';
import '../../bloc/attendance_event.dart';

class TakeAttendanceFAB extends StatelessWidget {
  final String courseId;
  final String courseName;
  final VoidCallback onReturn;

  const TakeAttendanceFAB({
    Key? key,
    required this.courseId,
    required this.courseName,
    required this.onReturn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        BlocNavigator.navigateWithNewBloc<AttendanceBloc, void>(
          context: context,
          pageBuilder: (context, bloc) => TakeAttendancePage(
            courseId: courseId,
            courseName: courseName,
          ),
          initEvents: [
            (bloc) => bloc.add(LoadEnrolledStudentsEvent(courseId: courseId)),
            (bloc) => bloc.add(LoadCourseSchedulesEvent(courseId: courseId)),
          ],
          onReturn: (_) {
            // Refresh data when returning from taking attendance
            if (context.mounted) {
              onReturn();
            }
          },
        );
      },
      label: Text(
        'Take Attendance',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      icon: Icon(
        Icons.edit,
        size: 5.w,
      ),
    );
  }
}
