class AIUsage {
  final String studentId;
  final int dailyCount;
  final DateTime lastReset;
  final int totalQuestions;
  final int dailyLimit;

  const AIUsage({
    required this.studentId,
    required this.dailyCount,
    required this.lastReset,
    required this.totalQuestions,
    this.dailyLimit = 20,
  });

  bool get hasReachedDailyLimit => dailyCount >= dailyLimit;

  bool get needsReset {
    final now = DateTime.now();
    final resetDate = DateTime(lastReset.year, lastReset.month, lastReset.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(resetDate);
  }

  AIUsage copyWith({
    String? studentId,
    int? dailyCount,
    DateTime? lastReset,
    int? totalQuestions,
    int? dailyLimit,
  }) {
    return AIUsage(
      studentId: studentId ?? this.studentId,
      dailyCount: dailyCount ?? this.dailyCount,
      lastReset: lastReset ?? this.lastReset,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      dailyLimit: dailyLimit ?? this.dailyLimit,
    );
  }
}
