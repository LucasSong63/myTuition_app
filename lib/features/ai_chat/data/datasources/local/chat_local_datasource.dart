// features/ai_chat/data/datasources/local/chat_local_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mytuition/core/result/result.dart';
import '../../models/chat_message_model.dart';
import '../../models/chat_session_model.dart';
import '../../models/ai_usage_model.dart';

class ChatLocalDatasource {
  final FirebaseFirestore firestore;

  ChatLocalDatasource(this.firestore);

  // FIXED: Better user document ID lookup method
  Future<String?> _getUserDocumentId(String studentId) async {
    try {
      print('Looking for user with studentId: $studentId');

      // Method 1: Try to find user by studentId field in document
      final userQueryByField = await firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (userQueryByField.docs.isNotEmpty) {
        final docId = userQueryByField.docs.first.id;
        print('Found user document by studentId field: $docId');
        return docId;
      }

      // Method 2: If not found, try direct document access (assuming studentId == docId)
      final directDoc =
          await firestore.collection('users').doc(studentId).get();
      if (directDoc.exists) {
        print('Found user document by direct access: $studentId');
        return studentId;
      }

      // Method 3: Search in email field if it contains the studentId
      final userQueryByEmail = await firestore
          .collection('users')
          .where('email', isEqualTo: '$studentId@student.mytuition.com')
          .limit(1)
          .get();

      if (userQueryByEmail.docs.isNotEmpty) {
        final docId = userQueryByEmail.docs.first.id;
        print('Found user document by email: $docId');
        return docId;
      }

      print('No user found with studentId: $studentId');
      return null;
    } catch (e) {
      print('Error finding user document: $e');
      return null;
    }
  }

  // FIXED: Alternative method that uses the document ID directly if lookup fails
  Future<String> _getOrCreateUserDocumentId(String studentId) async {
    // First try to find existing user
    final existingDocId = await _getUserDocumentId(studentId);
    if (existingDocId != null) {
      return existingDocId;
    }

    // If not found, use studentId as document ID (for direct access)
    print('Using studentId as document ID: $studentId');
    return studentId;
  }

  // Chat Sessions
  Future<Result<ChatSessionModel>> createChatSession(
      ChatSessionModel session) async {
    return ResultFactory.tryAsync(() async {
      print('Creating chat session for student: ${session.studentId}');

      final docRef = firestore.collection('chat_sessions').doc();
      final sessionWithId = session.copyWith(id: docRef.id);

      await docRef.set(sessionWithId.toFirestore());
      print('Chat session created: ${sessionWithId.id}');

      return sessionWithId;
    });
  }

  Future<Result<ChatSessionModel>> getChatSession(String sessionId) async {
    return ResultFactory.tryAsync(() async {
      print('Getting chat session: $sessionId');

      final doc =
          await firestore.collection('chat_sessions').doc(sessionId).get();

      if (!doc.exists) {
        throw Exception('Chat session not found: $sessionId');
      }

      final session = ChatSessionModel.fromFirestore(doc);
      print('Chat session found: ${session.id}');

      return session;
    });
  }

  Future<Result<ChatSessionModel?>> getActiveSession(String studentId) async {
    return ResultFactory.tryAsync(() async {
      print('Getting active session for student: $studentId');

      final query = await firestore
          .collection('chat_sessions')
          .where('studentId', isEqualTo: studentId)
          .where('isActive', isEqualTo: true)
          .orderBy('lastActive', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final session = ChatSessionModel.fromFirestore(query.docs.first);
        print('Active session found: ${session.id}');
        return session;
      }

      print('No active session found for student: $studentId');
      return null;
    });
  }

  Future<Result<void>> updateSession(ChatSessionModel session) async {
    return ResultFactory.tryAsync(() async {
      print('Updating session: ${session.id}');

      await firestore
          .collection('chat_sessions')
          .doc(session.id)
          .update(session.toFirestore());

      print('Session updated successfully');
    });
  }

  // Get archived sessions
  Future<Result<List<ChatSessionModel>>> getArchivedSessions(
      String studentId) async {
    return ResultFactory.tryAsync(() async {
      print('Getting archived sessions for student: $studentId');

      final query = await firestore
          .collection('chat_sessions')
          .where('studentId', isEqualTo: studentId)
          .where('isActive', isEqualTo: false)
          .orderBy('lastActive', descending: true)
          .limit(20) // Get last 20 archived sessions
          .get();

      final sessions =
          query.docs.map((doc) => ChatSessionModel.fromFirestore(doc)).toList();

      print('Archived sessions loaded: ${sessions.length}');
      return sessions;
    });
  }

  // Reactivate an archived session
  Future<Result<ChatSessionModel>> reactivateSession(
      String sessionId, String studentId) async {
    return ResultFactory.tryAsync(() async {
      print('Reactivating session: $sessionId for student: $studentId');

      // First deactivate any currently active sessions
      final activeSessionQuery = await firestore
          .collection('chat_sessions')
          .where('studentId', isEqualTo: studentId)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = firestore.batch();

      // Deactivate all currently active sessions
      for (final doc in activeSessionQuery.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      // Reactivate the target session
      final sessionRef = firestore.collection('chat_sessions').doc(sessionId);
      batch.update(sessionRef, {
        'isActive': true,
        'lastActive': Timestamp.fromDate(DateTime.now()),
      });

      await batch.commit();

      // Get the reactivated session
      final updatedSessionDoc = await sessionRef.get();
      final reactivatedSession =
          ChatSessionModel.fromFirestore(updatedSessionDoc);

      print('Session reactivated: ${reactivatedSession.id}');
      return reactivatedSession;
    });
  }

  // Delete a session permanently
  Future<Result<void>> deleteSession(String sessionId) async {
    return ResultFactory.tryAsync(() async {
      print('Deleting session: $sessionId');

      final batch = firestore.batch();

      // Delete all messages in the session
      final messagesQuery = await firestore
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .get();

      for (final messageDoc in messagesQuery.docs) {
        batch.delete(messageDoc.reference);
      }

      // Delete the session document
      batch.delete(firestore.collection('chat_sessions').doc(sessionId));

      await batch.commit();
      print('Session deleted successfully');
    });
  }

  // Chat Messages
  Future<Result<ChatMessageModel>> saveMessage(ChatMessageModel message) async {
    return ResultFactory.tryAsync(() async {
      print('Saving message to session: ${message.sessionId}');

      final docRef = firestore
          .collection('chat_sessions')
          .doc(message.sessionId)
          .collection('messages')
          .doc();

      final messageWithId = message.copyWith(id: docRef.id);
      await docRef.set(messageWithId.toFirestore());

      print('Message saved: ${messageWithId.id}');
      return messageWithId;
    });
  }

  Future<Result<List<ChatMessageModel>>> getSessionMessages(
      String sessionId) async {
    return ResultFactory.tryAsync(() async {
      print('Getting messages for session: $sessionId');

      final query = await firestore
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      final messages =
          query.docs.map((doc) => ChatMessageModel.fromFirestore(doc)).toList();

      print('Messages loaded: ${messages.length}');
      return messages;
    });
  }

  Future<Result<AIUsageModel>> getAIUsage(String studentId) async {
    return ResultFactory.tryAsync(() async {
      print('Getting AI usage for student: $studentId');

      // Get user document ID
      final userDocId = await _getOrCreateUserDocumentId(studentId);
      print('User document ID: $userDocId');

      // Get AI usage from user's subcollection
      final doc = await firestore
          .collection('users')
          .doc(userDocId)
          .collection('ai_usage')
          .doc('current')
          .get();

      if (doc.exists) {
        // FIXED: Pass the actual studentId, not doc.id
        final usage = AIUsageModel.fromFirestore(doc, studentId);
        print('AI usage found: ${usage.dailyCount}/${usage.dailyLimit}');
        return usage;
      } else {
        // Create initial usage record
        print('Creating initial AI usage record');
        final initialUsage = AIUsageModel.initial(studentId);

        await firestore
            .collection('users')
            .doc(userDocId)
            .collection('ai_usage')
            .doc('current')
            .set(initialUsage.toFirestore());

        print(
            'Initial AI usage created: ${initialUsage.dailyCount}/${initialUsage.dailyLimit}');
        return initialUsage;
      }
    });
  }

  Future<Result<void>> updateAIUsage(AIUsageModel usage) async {
    return ResultFactory.tryAsync(() async {
      print(
          'Updating AI usage for student: ${usage.studentId}'); // FIXED: Now shows correct studentId
      print('New usage: ${usage.dailyCount}/${usage.dailyLimit}');

      // Get user document ID using the ACTUAL studentId from the usage model
      final userDocId = await _getOrCreateUserDocumentId(usage.studentId);
      print('Updating user document: $userDocId');

      // Use merge: true to ensure we don't overwrite other fields
      await firestore
          .collection('users')
          .doc(userDocId)
          .collection('ai_usage')
          .doc('current')
          .set(usage.toFirestore(), SetOptions(merge: true));

      print('AI usage updated successfully');

      // Verify the update
      final verifyDoc = await firestore
          .collection('users')
          .doc(userDocId)
          .collection('ai_usage')
          .doc('current')
          .get();

      if (verifyDoc.exists) {
        final data = verifyDoc.data() as Map<String, dynamic>;
        print(
            'Verified update - dailyCount: ${data['dailyCount']} for student: ${usage.studentId}');
      }
    });
  }
}
