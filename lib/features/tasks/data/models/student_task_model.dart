import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/student_task.dart';

class StudentTaskModel extends StudentTask {
  const StudentTaskModel({
    required String id,
    required String taskId,
    required String studentId,
    String remarks = '',
    bool isCompleted = false,
    DateTime? completedAt,
  }) : super(
          id: id,
          taskId: taskId,
          studentId: studentId,
          remarks: remarks,
          isCompleted: isCompleted,
          completedAt: completedAt,
        );

  factory StudentTaskModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? completedAt;
    if (map['completedAt'] != null) {
      if (map['completedAt'] is Timestamp) {
        completedAt = (map['completedAt'] as Timestamp).toDate();
      } else if (map['completedAt'] is DateTime) {
        completedAt = map['completedAt'] as DateTime;
      }
    }

    return StudentTaskModel(
      id: docId,
      taskId: map['taskId'] ?? '',
      studentId: map['studentId'] ?? '',
      remarks: map['remarks'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      completedAt: completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'studentId': studentId,
      'remarks': remarks,
      'isCompleted': isCompleted,
      'completedAt': completedAt,
    };
  }
}
