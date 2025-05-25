import 'package:mytuition/core/result/result.dart';

import '../../domain/entities/ai_usage.dart';
import '../../domain/repositories/ai_usage_repository.dart';
import '../datasources/local/chat_local_datasource.dart';
import '../models/ai_usage_model.dart';

class AIUsageRepositoryImpl implements AIUsageRepository {
  final ChatLocalDatasource localDatasource;

  AIUsageRepositoryImpl(this.localDatasource);

  @override
  Future<Result<AIUsage>> getAIUsage(String studentId) async {
    return localDatasource.getAIUsage(studentId);
  }

  @override
  Future<Result<AIUsage>> incrementUsage(String studentId) async {
    final currentUsageResult = await localDatasource.getAIUsage(studentId);

    return switch (currentUsageResult) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success(data: final currentUsage) =>
        await _incrementAndSave(currentUsage),
    };
  }

  Future<Result<AIUsage>> _incrementAndSave(AIUsageModel currentUsage) async {
    final updatedUsage = currentUsage.copyWith(
      dailyCount: currentUsage.dailyCount + 1,
      totalQuestions: currentUsage.totalQuestions + 1,
    );

    final updateResult = await localDatasource.updateAIUsage(updatedUsage);

    return switch (updateResult) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success() => Success(updatedUsage),
    };
  }

  @override
  Future<Result<bool>> canSendMessage(String studentId) async {
    final usageResult = await localDatasource.getAIUsage(studentId);

    return switch (usageResult) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success(data: final usage) => await _checkCanSend(usage),
    };
  }

  Future<Result<bool>> _checkCanSend(AIUsageModel usage) async {
    // Check if daily count needs reset
    final resetUsageResult = await _resetDailyCountIfNeeded(usage);

    return switch (resetUsageResult) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success(data: final resetUsage) =>
        Success(!resetUsage.hasReachedDailyLimit),
    };
  }

  @override
  Future<Result<AIUsage>> resetDailyCountIfNeeded(String studentId) async {
    final usageResult = await localDatasource.getAIUsage(studentId);

    return switch (usageResult) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success(data: final usage) => await _resetDailyCountIfNeeded(usage),
    };
  }

  Future<Result<AIUsageModel>> _resetDailyCountIfNeeded(
      AIUsageModel usage) async {
    if (!usage.needsReset) {
      return Success(usage);
    }

    final now = DateTime.now();
    final resetUsage = usage.copyWith(
      dailyCount: 0,
      lastReset: DateTime(now.year, now.month, now.day),
    );

    final updateResult = await localDatasource.updateAIUsage(resetUsage);

    return switch (updateResult) {
      Error(message: final errorMessage) => Error(errorMessage),
      Success() => Success(resetUsage),
    };
  }
}
