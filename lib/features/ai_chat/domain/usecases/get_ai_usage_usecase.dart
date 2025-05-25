import 'package:mytuition/core/result/result.dart';

import '../entities/ai_usage.dart';
import '../repositories/ai_usage_repository.dart';

class GetAIUsageUseCase {
  final AIUsageRepository aiUsageRepository;

  GetAIUsageUseCase(this.aiUsageRepository);

  Future<Result<AIUsage>> call(String studentId) async {
    // Reset daily count if needed, then get usage
    await aiUsageRepository.resetDailyCountIfNeeded(studentId);
    return aiUsageRepository.getAIUsage(studentId);
  }
}
