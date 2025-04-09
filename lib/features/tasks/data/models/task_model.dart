import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required String id,
    required String courseId,
    required String title,
    required String description,
    required DateTime createdAt,
    DateTime? dueDate,
    bool isCompleted = false,
  }) : super(
          id: id,
          courseId: courseId,
          title: title,
          description: description,
          createdAt: createdAt,
          dueDate: dueDate,
          isCompleted: isCompleted,
        );

  factory TaskModel.fromMap(Map<String, dynamic> map, String docId) {
    // Handle Firestore timestamps
    DateTime createdAt;
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is DateTime) {
      createdAt = map['createdAt'] as DateTime;
    } else {
      createdAt = DateTime.now();
    }

    DateTime? dueDate;
    if (map['dueDate'] != null) {
      if (map['dueDate'] is Timestamp) {
        dueDate = (map['dueDate'] as Timestamp).toDate();
      } else if (map['dueDate'] is DateTime) {
        dueDate = map['dueDate'] as DateTime;
      }
    }

    return TaskModel(
      id: docId,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: createdAt,
      dueDate: dueDate,
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'createdAt': createdAt,
      'dueDate': dueDate,
      'isCompleted': isCompleted,
    };
  }
}
