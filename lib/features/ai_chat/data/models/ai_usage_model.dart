import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ai_usage.dart';

class AIUsageModel extends AIUsage {
  const AIUsageModel({
    required String studentId,
    required int dailyCount,
    required DateTime lastReset,
    required int totalQuestions,
    int dailyLimit = 20,
  }) : super(
          studentId: studentId,
          dailyCount: dailyCount,
          lastReset: lastReset,
          totalQuestions: totalQuestions,
          dailyLimit: dailyLimit,
        );

  factory AIUsageModel.fromEntity(AIUsage entity) {
    return AIUsageModel(
      studentId: entity.studentId,
      dailyCount: entity.dailyCount,
      lastReset: entity.lastReset,
      totalQuestions: entity.totalQuestions,
      dailyLimit: entity.dailyLimit,
    );
  }

  // FIXED: Accept studentId parameter instead of using doc.id
  factory AIUsageModel.fromFirestore(DocumentSnapshot doc, String studentId) {
    final data = doc.data() as Map<String, dynamic>;
    return AIUsageModel(
      studentId: studentId,
      // Use the passed studentId, not doc.id
      dailyCount: data['dailyCount'] ?? 0,
      lastReset: (data['lastReset'] as Timestamp).toDate(),
      totalQuestions: data['totalQuestions'] ?? 0,
      dailyLimit: data['dailyLimit'] ?? 20,
    );
  }

  factory AIUsageModel.initial(String studentId) {
    final now = DateTime.now();
    return AIUsageModel(
      studentId: studentId,
      dailyCount: 0,
      lastReset: DateTime(now.year, now.month, now.day),
      totalQuestions: 0,
      dailyLimit: 20,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dailyCount': dailyCount,
      'lastReset': Timestamp.fromDate(lastReset),
      'totalQuestions': totalQuestions,
      'dailyLimit': dailyLimit,
      // Note: We don't store studentId in the document because
      // it's implied by the document path
    };
  }

  AIUsageModel copyWith({
    String? studentId,
    int? dailyCount,
    DateTime? lastReset,
    int? totalQuestions,
    int? dailyLimit,
  }) {
    return AIUsageModel(
      studentId: studentId ?? this.studentId,
      dailyCount: dailyCount ?? this.dailyCount,
      lastReset: lastReset ?? this.lastReset,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      dailyLimit: dailyLimit ?? this.dailyLimit,
    );
  }
}
