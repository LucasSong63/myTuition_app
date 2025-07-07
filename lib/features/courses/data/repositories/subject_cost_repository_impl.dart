// lib/features/courses/data/repositories/subject_cost_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subject_cost.dart';
import '../../domain/repositories/subject_cost_repository.dart';

class SubjectCostRepositoryImpl implements SubjectCostRepository {
  final FirebaseFirestore _firestore;

  SubjectCostRepositoryImpl(this._firestore);

  @override
  Future<List<SubjectCost>> getAllSubjectCosts() async {
    final querySnapshot = await _firestore
        .collection('subject_costs')
        .orderBy('subjectName')
        .orderBy('grade')
        .get();

    return querySnapshot.docs
        .map((doc) => SubjectCost.fromFirestore(doc))
        .toList();
  }

  @override
  Future<SubjectCost?> getSubjectCost(String subjectId) async {
    final querySnapshot = await _firestore
        .collection('subject_costs')
        .where('subjectId', isEqualTo: subjectId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return SubjectCost.fromFirestore(querySnapshot.docs.first);
  }

  @override
  Future<void> addSubjectCost({
    required String subjectName,
    required int grade,
    required double cost,
  }) async {
    final now = DateTime.now();
    final subjectId = '${subjectName.toLowerCase().replaceAll(' ', '_')}_grade_$grade';

    await _firestore.collection('subject_costs').add({
      'subjectId': subjectId,
      'subjectName': subjectName,
      'grade': grade,
      'cost': cost,
      'lastUpdated': Timestamp.fromDate(now),
    });
  }

  @override
  Future<void> updateSubjectCost({
    required String subjectCostId,
    required int grade,
    required double newCost,
  }) async {
    final now = DateTime.now();

    await _firestore.collection('subject_costs').doc(subjectCostId).update({
      'grade': grade,
      'cost': newCost,
      'lastUpdated': Timestamp.fromDate(now),
    });
  }

  @override
  Future<void> deleteSubjectCost({
    required String subjectCostId,
  }) async {
    await _firestore.collection('subject_costs').doc(subjectCostId).delete();
  }
}
