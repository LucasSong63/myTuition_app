import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_session.dart';

class ChatSessionModel extends ChatSession {
  const ChatSessionModel({
    required String id,
    required String studentId,
    String? openaiThreadId,
    required DateTime createdAt,
    required DateTime lastActive,
    int messageCount = 0,
    bool isActive = true,
  }) : super(
          id: id,
          studentId: studentId,
          openaiThreadId: openaiThreadId,
          createdAt: createdAt,
          lastActive: lastActive,
          messageCount: messageCount,
          isActive: isActive,
        );

  factory ChatSessionModel.fromEntity(ChatSession entity) {
    return ChatSessionModel(
      id: entity.id,
      studentId: entity.studentId,
      openaiThreadId: entity.openaiThreadId,
      createdAt: entity.createdAt,
      lastActive: entity.lastActive,
      messageCount: entity.messageCount,
      isActive: entity.isActive,
    );
  }

  factory ChatSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatSessionModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      openaiThreadId: data['openaiThreadId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActive: (data['lastActive'] as Timestamp).toDate(),
      messageCount: data['messageCount'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'openaiThreadId': openaiThreadId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'messageCount': messageCount,
      'isActive': isActive,
      // Note: OpenAI threads expire after 60 days of inactivity
      // The app will automatically create a new thread if the old one expires
    };
  }

  ChatSessionModel copyWith({
    String? id,
    String? studentId,
    String? openaiThreadId,
    DateTime? createdAt,
    DateTime? lastActive,
    int? messageCount,
    bool? isActive,
  }) {
    return ChatSessionModel(
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
