// lib/features/courses/domain/entities/subject_cost.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SubjectCost extends Equatable {
  final String id;
  final String subjectId;
  final String subjectName;
  final double cost;
  final DateTime lastUpdated;

  const SubjectCost({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.cost,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [id, subjectId, cost];

  factory SubjectCost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubjectCost(
      id: doc.id,
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
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
      'cost': cost,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
