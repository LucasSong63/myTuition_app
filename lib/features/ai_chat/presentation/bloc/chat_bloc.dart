// features/ai_chat/presentation/bloc/chat_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/core/result/result.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/get_or_create_active_session_usecase.dart';
import '../../domain/usecases/get_session_messages_usecase.dart';
import '../../domain/usecases/get_ai_usage_usecase.dart';
import '../../domain/usecases/start_new_session_usecase.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetOrCreateActiveSessionUseCase getOrCreateActiveSessionUseCase;
  final GetSessionMessagesUseCase getSessionMessagesUseCase;
  final GetAIUsageUseCase getAIUsageUseCase;
  final StartNewSessionUseCase startNewSessionUseCase;

  ChatBloc({
    required this.sendMessageUseCase,
    required this.getOrCreateActiveSessionUseCase,
    required this.getSessionMessagesUseCase,
    required this.getAIUsageUseCase,
    required this.startNewSessionUseCase,
  }) : super(ChatInitial()) {
    on<InitializeChatEvent>(_onInitializeChat);
    on<SendMessageEvent>(_onSendMessage);
    on<LoadMessagesEvent>(_onLoadMessages);
    on<StartNewSessionEvent>(_onStartNewSession);
    on<CheckDailyLimitEvent>(_onCheckDailyLimit);
  }

  Future<void> _onInitializeChat(
    InitializeChatEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());

    try {
      print('Initializing chat for student: ${event.studentId}');

      // Get or create active session
      final sessionResult =
          await getOrCreateActiveSessionUseCase(event.studentId);

      switch (sessionResult) {
        case Error(message: final errorMessage):
          print('Session error: $errorMessage');
          emit(ChatError(errorMessage));

        case Success(data: final session):
          print('Session created/found: ${session.id}');

          // Get messages for the session
          final messagesResult = await getSessionMessagesUseCase(session.id);

          switch (messagesResult) {
            case Error(message: final errorMessage):
              print('Messages error: $errorMessage');
              emit(ChatError(errorMessage));

            case Success(data: final messages):
              print('Messages loaded: ${messages.length}');

              // Get AI usage
              final usageResult = await getAIUsageUseCase(event.studentId);

              switch (usageResult) {
                case Error(message: final errorMessage):
                  print('Usage error: $errorMessage');
                  emit(ChatError(errorMessage));

                case Success(data: final usage):
                  print(
                      'Usage loaded: ${usage.dailyCount}/${usage.dailyLimit}');

                  if (usage.hasReachedDailyLimit) {
                    emit(DailyLimitReached(
                      session: session,
                      messages: messages,
                      aiUsage: usage,
                    ));
                  } else {
                    emit(ChatLoaded(
                      session: session,
                      messages: messages,
                      aiUsage: usage,
                    ));
                  }
              }
          }
      }
    } catch (e) {
      print('Initialization error: $e');
      emit(ChatError('An unexpected error occurred: $e'));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    print('\n=== SEND MESSAGE DEBUG ===');
    print('Message: ${event.message}');
    print('Session ID: ${currentState.session.id}');
    print(
        'Session Thread ID: ${currentState.session.openaiThreadId ?? "NO THREAD ID"}');
    print('Session is active: ${currentState.session.isActive}');
    print(
        'Current usage: ${currentState.aiUsage.dailyCount}/${currentState.aiUsage.dailyLimit}');
    print('=======================\n');

    // Check daily limit before sending
    if (currentState.aiUsage.hasReachedDailyLimit) {
      print('Daily limit reached');
      emit(DailyLimitReached(
        session: currentState.session,
        messages: currentState.messages,
        aiUsage: currentState.aiUsage,
      ));
      return;
    }

    // Add user message optimistically
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: currentState.session.id,
      content: event.message,
      type: ChatMessageType.user,
      timestamp: DateTime.now(),
    );

    // Add loading message for AI response
    final loadingMessage = ChatMessage(
      id: 'loading',
      sessionId: currentState.session.id,
      content: 'Thinking...',
      type: ChatMessageType.assistant,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    final updatedMessages = [
      ...currentState.messages,
      userMessage,
      loadingMessage
    ];

    emit(currentState.copyWith(
      messages: updatedMessages,
      isSendingMessage: true,
    ));

    print('Calling sendMessageUseCase...');

    // Send message to AI
    final result = await sendMessageUseCase(
      sessionId: currentState.session.id,
      message: event.message,
      studentId: currentState.session.studentId,
    );

    switch (result) {
      case Error(message: final errorMessage):
        print('Send message error: $errorMessage');

        // Remove loading message and show error
        final messagesWithoutLoading =
            updatedMessages.where((msg) => msg.id != 'loading').toList();

        if (errorMessage.contains('daily question limit')) {
          // Get updated usage and show limit reached
          await _getUpdatedUsageAndShowLimit(
              currentState, messagesWithoutLoading, emit);
        } else {
          emit(currentState.copyWith(
            messages: messagesWithoutLoading,
            isSendingMessage: false,
          ));
          // Don't emit error state immediately, keep chat functional
          // emit(ChatError(errorMessage));
        }

      case Success(data: final aiResponse):
        print(
            'AI response received: ${aiResponse.content.substring(0, 50)}...');

        // Replace loading message with actual AI response
        final finalMessages = updatedMessages
            .where((msg) => msg.id != 'loading')
            .toList()
          ..add(aiResponse);

        print('Getting updated AI usage...');

        // Get updated AI usage - Force refresh
        final usageResult =
            await getAIUsageUseCase(currentState.session.studentId);

        switch (usageResult) {
          case Error(message: final errorMessage):
            print('Usage refresh error: $errorMessage');
            emit(currentState.copyWith(
              messages: finalMessages,
              isSendingMessage: false,
            ));

          case Success(data: final updatedUsage):
            print(
                'Updated usage: ${updatedUsage.dailyCount}/${updatedUsage.dailyLimit}');

            // If this was the first message (no thread ID), reload the session to get the thread ID
            ChatSession sessionToUse = currentState.session;
            if (currentState.session.openaiThreadId == null ||
                currentState.session.openaiThreadId!.isEmpty) {
              print(
                  'First message sent, reloading session to get thread ID...');
              // Re-fetch the session to get the updated thread ID
              final reloadedSessionResult =
                  await getOrCreateActiveSessionUseCase(
                      currentState.session.studentId);
              if (reloadedSessionResult
                  case Success(data: final reloadedSession)) {
                print(
                    'Session reloaded with thread ID: ${reloadedSession.openaiThreadId}');
                sessionToUse = reloadedSession;
              }
            }

            emit(ChatLoaded(
              session: sessionToUse,
              messages: finalMessages,
              aiUsage: updatedUsage,
              isSendingMessage: false,
            ));
        }
    }
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    final result = await getSessionMessagesUseCase(event.sessionId);

    switch (result) {
      case Error(message: final errorMessage):
        emit(ChatError(errorMessage));

      case Success(data: final messages):
        emit(currentState.copyWith(messages: messages));
    }
  }

  Future<void> _onStartNewSession(
    StartNewSessionEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());

    print('Starting new session for student: ${event.studentId}');

    final result = await startNewSessionUseCase(event.studentId);

    switch (result) {
      case Error(message: final errorMessage):
        print('New session error: $errorMessage');
        emit(ChatError(errorMessage));

      case Success(data: final newSession):
        print('New session created: ${newSession.id}');

        // Get AI usage
        final usageResult = await getAIUsageUseCase(event.studentId);

        switch (usageResult) {
          case Error(message: final errorMessage):
            print('Usage error: $errorMessage');
            emit(ChatError(errorMessage));

          case Success(data: final usage):
            print(
                'Usage for new session: ${usage.dailyCount}/${usage.dailyLimit}');

            emit(ChatLoaded(
              session: newSession,
              messages: [], // New session has no messages
              aiUsage: usage,
            ));
        }
    }
  }

  Future<void> _onCheckDailyLimit(
    CheckDailyLimitEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    final usageResult = await getAIUsageUseCase(event.studentId);

    switch (usageResult) {
      case Error(message: final errorMessage):
        emit(ChatError(errorMessage));

      case Success(data: final usage):
        if (usage.hasReachedDailyLimit) {
          emit(DailyLimitReached(
            session: currentState.session,
            messages: currentState.messages,
            aiUsage: usage,
          ));
        } else {
          emit(currentState.copyWith(aiUsage: usage));
        }
    }
  }

  Future<void> _getUpdatedUsageAndShowLimit(
    ChatLoaded currentState,
    List<ChatMessage> messages,
    Emitter<ChatState> emit,
  ) async {
    final usageResult = await getAIUsageUseCase(currentState.session.studentId);

    switch (usageResult) {
      case Error():
        emit(currentState.copyWith(
          messages: messages,
          isSendingMessage: false,
        ));

      case Success(data: final updatedUsage):
        emit(DailyLimitReached(
          session: currentState.session,
          messages: messages,
          aiUsage: updatedUsage,
        ));
    }
  }
}
