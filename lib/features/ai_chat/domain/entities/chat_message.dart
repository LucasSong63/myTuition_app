class ChatMessage {
  final String id;
  final String sessionId;
  final String content;
  final ChatMessageType type;
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isLoading = false,
  });

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    String? content,
    ChatMessageType? type,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

enum ChatMessageType { user, assistant }
