// lib/features/courses/domain/entities/subject_cost.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SubjectCost extends Equatable {
  final String id;
  final String subjectId;
  final String subjectName;
  final int grade;
  final double cost;
  final DateTime lastUpdated;

  const SubjectCost({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.grade,
    required this.cost,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [id, subjectId, grade, cost];

  factory SubjectCost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubjectCost(
      id: doc.id,
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      grade: data['grade'] ?? 1,
      cost: (data['cost'] ?? 0).toDouble(),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'subjectId': subjectId,
      'subjectName': subjectName,
      'grade': grade,
      'cost': cost,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
