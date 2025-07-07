// lib/features/courses/domain/repositories/subject_cost_repository.dart
import '../entities/subject_cost.dart';

abstract class SubjectCostRepository {
  /// Get all subject costs
  Future<List<SubjectCost>> getAllSubjectCosts();

  /// Get cost for a specific subject
  Future<SubjectCost?> getSubjectCost(String subjectId);

  /// Add a new subject cost
  Future<void> addSubjectCost({
    required String subjectName,
    required int grade,
    required double cost,
  });

  /// Update an existing subject cost
  Future<void> updateSubjectCost({
    required String subjectCostId,
    required int grade,
    required double newCost,
  });

  /// Delete a subject cost
  Future<void> deleteSubjectCost({
    required String subjectCostId,
  });
}
