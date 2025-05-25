class ChatSession {
  final String id;
  final String studentId;
  final String? openaiThreadId;
  final DateTime createdAt;
  final DateTime lastActive;
  final int messageCount;
  final bool isActive;

  const ChatSession({
    required this.id,
    required this.studentId,
    this.openaiThreadId,
    required this.createdAt,
    required this.lastActive,
    this.messageCount = 0,
    this.isActive = true,
  });

  ChatSession copyWith({
    String? id,
    String? studentId,
    String? openaiThreadId,
    DateTime? createdAt,
    DateTime? lastActive,
    int? messageCount,
    bool? isActive,
  }) {
    return ChatSession(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      openaiThreadId: openaiThreadId ?? this.openaiThreadId,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      messageCount: messageCount ?? this.messageCount,
      isActive: isActive ?? this.isActive,
    );
  }
}
