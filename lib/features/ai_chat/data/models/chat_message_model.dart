import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required String id,
    required String sessionId,
    required String content,
    required ChatMessageType type,
    required DateTime timestamp,
    bool isLoading = false,
  }) : super(
          id: id,
          sessionId: sessionId,
          content: content,
          type: type,
          timestamp: timestamp,
          isLoading: isLoading,
        );

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      sessionId: entity.sessionId,
      content: entity.content,
      type: entity.type,
      timestamp: entity.timestamp,
      isLoading: entity.isLoading,
    );
  }

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      content: data['content'] ?? '',
      type: ChatMessageType.values.firstWhere(
        (type) => type.toString() == data['type'],
        orElse: () => ChatMessageType.user,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isLoading: false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'content': content,
      'type': type.toString(),
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? sessionId,
    String? content,
    ChatMessageType? type,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
