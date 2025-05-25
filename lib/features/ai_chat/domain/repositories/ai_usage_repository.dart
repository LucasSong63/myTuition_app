import 'package:mytuition/core/result/result.dart';

import '../entities/ai_usage.dart';

abstract class AIUsageRepository {
  /// Get current AI usage for student
  Future<Result<AIUsage>> getAIUsage(String studentId);

  /// Increment daily usage count
  Future<Result<AIUsage>> incrementUsage(String studentId);

  /// Check if student can send more messages today
  Future<Result<bool>> canSendMessage(String studentId);

  /// Reset daily count if new day
  Future<Result<AIUsage>> resetDailyCountIfNeeded(String studentId);
}
