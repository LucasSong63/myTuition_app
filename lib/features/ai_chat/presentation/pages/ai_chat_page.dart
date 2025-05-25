// features/ai_chat/presentation/pages/ai_chat_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_messages_list.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/daily_usage_indicator.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/daily_limit_reached_widget.dart';
import '../../../../config/theme/app_colors.dart';

class AIChatPage extends StatefulWidget {
  final String studentId;

  const AIChatPage({Key? key, required this.studentId}) : super(key: key);

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // DEBUG: Print studentId to verify it's being passed correctly
    print('AIChatPage initialized with studentId: "${widget.studentId}"');
    print('StudentId is empty: ${widget.studentId.isEmpty}');
    print('StudentId is null: ${widget.studentId == null}');

    // Initialize chat when page loads
    if (widget.studentId.isNotEmpty) {
      context.read<ChatBloc>().add(InitializeChatEvent(widget.studentId));
    } else {
      print('ERROR: StudentId is empty, cannot initialize chat');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(String message) {
    if (message.trim().isNotEmpty) {
      print('Sending message: $message');
      context.read<ChatBloc>().add(SendMessageEvent(message.trim()));
      _messageController.clear();

      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _startNewSession() {
    print('Starting new session for studentId: ${widget.studentId}');
    context.read<ChatBloc>().add(StartNewSessionEvent(widget.studentId));
  }

  // DEBUG: Method to show debug info
  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('StudentId: "${widget.studentId}"'),
            Text('Is Empty: ${widget.studentId.isEmpty}'),
            Text('Length: ${widget.studentId.length}'),
            const SizedBox(height: 10),
            const Text('Current BLoC State:'),
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return Text(state.runtimeType.toString());
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handle empty studentId case
    if (widget.studentId.isEmpty) {
      return _buildEmptyStudentIdState();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      resizeToAvoidBottomInset: true,
      // FIXED: Remove SafeArea from here and let the ChatAppBar handle status bar
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          // Auto-scroll when new messages arrive
          if (state is ChatLoaded && !state.isSendingMessage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        },
        builder: (context, state) {
          if (state is ChatLoading) {
            return _buildLoadingState();
          } else if (state is ChatError) {
            return _buildErrorState(state.message);
          } else if (state is DailyLimitReached) {
            return _buildDailyLimitReachedState(state);
          } else if (state is ChatLoaded) {
            return _buildChatState(state);
          }

          return _buildInitialState();
        },
      ),
      // Add debug FAB if there are issues
      floatingActionButton: widget.studentId.isEmpty
          ? FloatingActionButton(
              mini: true,
              onPressed: _showDebugInfo,
              child: const Icon(Icons.bug_report),
            )
          : null,
    );
  }

  Widget _buildEmptyStudentIdState() {
    return Column(
      children: [
        AppBar(
          title: const Text('AI Tutor'),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_outlined,
                      size: 48,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Student ID Missing',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load chat. Student ID is missing from authentication.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMedium,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _showDebugInfo,
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Debug Info'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        ChatAppBar(
          title: 'AI Tutor',
          studentId: widget.studentId.isNotEmpty ? widget.studentId : null,
          onNewSession: _startNewSession,
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.primaryBlue),
                const SizedBox(height: 16),
                Text(
                  'Setting up your AI tutor...',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textMedium,
                      ),
                ),
                if (widget.studentId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Student: ${widget.studentId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textLight,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Column(
      children: [
        ChatAppBar(
          title: 'AI Tutor',
          studentId: widget.studentId.isNotEmpty ? widget.studentId : null,
          onNewSession: widget.studentId.isNotEmpty ? _startNewSession : null,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Oops! Something went wrong',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMedium,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Student ID: ${widget.studentId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textLight,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (widget.studentId.isNotEmpty) {
                            context
                                .read<ChatBloc>()
                                .add(InitializeChatEvent(widget.studentId));
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: _showDebugInfo,
                        icon: const Icon(Icons.bug_report),
                        label: const Text('Debug'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialState() {
    return Column(
      children: [
        ChatAppBar(
          title: 'AI Tutor',
          studentId: widget.studentId.isNotEmpty ? widget.studentId : null,
          onNewSession: widget.studentId.isNotEmpty ? _startNewSession : null,
        ),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyLimitReachedState(DailyLimitReached state) {
    return Column(
      children: [
        ChatAppBar(
          title: 'AI Tutor',
          studentId: widget.studentId,
          onNewSession: _startNewSession,
        ),
        DailyUsageIndicator(usage: state.aiUsage),
        Expanded(
          child: ChatMessagesList(
            messages: state.messages,
            scrollController: _scrollController,
          ),
        ),
        DailyLimitReachedWidget(
          usage: state.aiUsage,
          onStartNewSession: _startNewSession,
        ),
      ],
    );
  }

  Widget _buildChatState(ChatLoaded state) {
    return Column(
      children: [
        ChatAppBar(
          title: 'AI Tutor',
          studentId: widget.studentId,
          // Always pass studentId for history button
          onNewSession: _startNewSession,
        ),
        DailyUsageIndicator(usage: state.aiUsage),
        Expanded(
          child: ChatMessagesList(
            messages: state.messages,
            scrollController: _scrollController,
          ),
        ),
        ChatInputField(
          controller: _messageController,
          onSend: _sendMessage,
          isLoading: state.isSendingMessage,
          canSend: !state.aiUsage.hasReachedDailyLimit,
        ),
      ],
    );
  }
}
