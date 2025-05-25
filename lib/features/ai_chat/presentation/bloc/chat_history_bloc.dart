import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/core/result/result.dart';
import '../../domain/usecases/get_archived_sessions_usecase.dart';
import '../../domain/usecases/reactivate_session_usecase.dart';
import '../../domain/usecases/delete_session_usecase.dart';
import 'chat_history_event.dart';
import 'chat_history_state.dart';

class ChatHistoryBloc extends Bloc<ChatHistoryEvent, ChatHistoryState> {
  final GetArchivedSessionsUseCase getArchivedSessionsUseCase;
  final ReactivateSessionUseCase reactivateSessionUseCase;
  final DeleteSessionUseCase deleteSessionUseCase;

  ChatHistoryBloc({
    required this.getArchivedSessionsUseCase,
    required this.reactivateSessionUseCase,
    required this.deleteSessionUseCase,
  }) : super(ChatHistoryInitial()) {
    on<LoadArchivedSessionsEvent>(_onLoadArchivedSessions);
    on<ReactivateSessionEvent>(_onReactivateSession);
    on<DeleteSessionEvent>(_onDeleteSession);
    on<RefreshHistoryEvent>(_onRefreshHistory);
  }

  Future<void> _onLoadArchivedSessions(
    LoadArchivedSessionsEvent event,
    Emitter<ChatHistoryState> emit,
  ) async {
    emit(ChatHistoryLoading());

    print('Loading archived sessions for student: ${event.studentId}');

    final result = await getArchivedSessionsUseCase(event.studentId);

    switch (result) {
      case Error(message: final errorMessage):
        print('Error loading archived sessions: $errorMessage');
        emit(ChatHistoryError(errorMessage));

      case Success(data: final sessions):
        print('Archived sessions loaded: ${sessions.length}');
        emit(ChatHistoryLoaded(archivedSessions: sessions));
    }
  }

  Future<void> _onReactivateSession(
    ReactivateSessionEvent event,
    Emitter<ChatHistoryState> emit,
  ) async {
    if (state is! ChatHistoryLoaded) return;

    final currentState = state as ChatHistoryLoaded;

    print('Reactivating session: ${event.sessionId}');

    final result =
        await reactivateSessionUseCase(event.sessionId, event.studentId);

    switch (result) {
      case Error(message: final errorMessage):
        print('Error reactivating session: $errorMessage');
        emit(ChatHistoryError(errorMessage));
        // Return to previous state after showing error
        emit(currentState);

      case Success(data: final reactivatedSession):
        print('Session reactivated: ${reactivatedSession.id}');
        emit(SessionReactivated(reactivatedSession));
    }
  }

  Future<void> _onDeleteSession(
    DeleteSessionEvent event,
    Emitter<ChatHistoryState> emit,
  ) async {
    if (state is! ChatHistoryLoaded) return;

    final currentState = state as ChatHistoryLoaded;

    print('Deleting session: ${event.sessionId}');

    final result = await deleteSessionUseCase(event.sessionId);

    switch (result) {
      case Error(message: final errorMessage):
        print('Error deleting session: $errorMessage');
        emit(ChatHistoryError(errorMessage));
        // Return to previous state after showing error
        emit(currentState);

      case Success():
        print('Session deleted successfully: ${event.sessionId}');

        // Remove the deleted session from the list
        final updatedSessions = currentState.archivedSessions
            .where((session) => session.id != event.sessionId)
            .toList();

        emit(ChatHistoryLoaded(archivedSessions: updatedSessions));
        emit(SessionDeleted(event.sessionId));
    }
  }

  Future<void> _onRefreshHistory(
    RefreshHistoryEvent event,
    Emitter<ChatHistoryState> emit,
  ) async {
    if (state is! ChatHistoryLoaded) return;

    final currentState = state as ChatHistoryLoaded;
    emit(currentState.copyWith(isRefreshing: true));

    print('Refreshing archived sessions for student: ${event.studentId}');

    final result = await getArchivedSessionsUseCase(event.studentId);

    switch (result) {
      case Error(message: final errorMessage):
        print('Error refreshing archived sessions: $errorMessage');
        emit(currentState.copyWith(isRefreshing: false));
        emit(ChatHistoryError(errorMessage));

      case Success(data: final sessions):
        print('Archived sessions refreshed: ${sessions.length}');
        emit(ChatHistoryLoaded(
          archivedSessions: sessions,
          isRefreshing: false,
        ));
    }
  }
}
