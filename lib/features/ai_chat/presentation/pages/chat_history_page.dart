// features/ai_chat/presentation/pages/chat_history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../config/theme/app_colors.dart';
import '../../domain/entities/chat_session.dart';
import '../bloc/chat_history_bloc.dart';
import '../bloc/chat_history_event.dart';
import '../bloc/chat_history_state.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';

class ChatHistoryPage extends StatefulWidget {
  final String studentId;

  const ChatHistoryPage({Key? key, required this.studentId}) : super(key: key);

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  @override
  void initState() {
    super.initState();
    // Load archived sessions when page opens
    context
        .read<ChatHistoryBloc>()
        .add(LoadArchivedSessionsEvent(widget.studentId));
  }

  void _resumeSession(ChatSession session) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );

      // Reactivate the session
      context.read<ChatHistoryBloc>().add(
            ReactivateSessionEvent(session.id, widget.studentId),
          );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorSnackBar('Failed to resume chat session');
    }
  }

  void _deleteSession(ChatSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat Session'),
        content: Text(
          'Are you sure you want to permanently delete this chat session? This action cannot be undone.\n\n'
          'Session from ${_formatDate(session.lastActive)} with ${session.messageCount} messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<ChatHistoryBloc>()
                  .add(DeleteSessionEvent(session.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSessionActions(ChatSession session) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chat Session Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: AppColors.primaryBlue,
                ),
              ),
              title: const Text('Resume Chat'),
              subtitle: const Text('Continue this conversation'),
              onTap: () {
                Navigator.pop(context);
                _resumeSession(session);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
              ),
              title: const Text('Delete Session'),
              subtitle: const Text('Permanently remove this chat'),
              onTap: () {
                Navigator.pop(context);
                _deleteSession(session);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Chat History'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              context.read<ChatHistoryBloc>().add(
                    RefreshHistoryEvent(widget.studentId),
                  );
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocConsumer<ChatHistoryBloc, ChatHistoryState>(
        listener: (context, state) {
          if (state is SessionReactivated) {
            Navigator.pop(context); // Close loading dialog
            Navigator.pop(context); // Go back to chat

            // Trigger chat reload with reactivated session
            context.read<ChatBloc>().add(
                  InitializeChatEvent(widget.studentId),
                );

            _showSuccessSnackBar('Chat session resumed successfully!');
          } else if (state is SessionDeleted) {
            _showSuccessSnackBar('Chat session deleted successfully');
          } else if (state is ChatHistoryError) {
            Navigator.of(context, rootNavigator: true)
                .popUntil((route) => route.isFirst);
            _showErrorSnackBar(state.message);
          }
        },
        builder: (context, state) {
          if (state is ChatHistoryLoading) {
            return _buildLoadingState();
          } else if (state is ChatHistoryLoaded) {
            return _buildHistoryList(state);
          } else if (state is ChatHistoryError) {
            return _buildErrorState(state.message);
          }

          return _buildLoadingState();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryBlue),
          SizedBox(height: 16),
          Text(
            'Loading chat history...',
            style: TextStyle(color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
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
              'Failed to Load History',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMedium,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<ChatHistoryBloc>().add(
                      LoadArchivedSessionsEvent(widget.studentId),
                    );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(ChatHistoryLoaded state) {
    if (state.archivedSessions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ChatHistoryBloc>().add(
              RefreshHistoryEvent(widget.studentId),
            );
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.archivedSessions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final session = state.archivedSessions[index];
          return _buildSessionCard(session);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                size: 48,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Chat History Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your previous conversations will appear here when you start new chat sessions.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMedium,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.chat),
              label: const Text('Start Chatting'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(ChatSession session) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showSessionActions(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat Session',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          _formatDate(session.lastActive),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMedium,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.more_vert,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${session.messageCount} messages',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMedium,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Archived',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.accentTeal,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to resume or manage this conversation',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textLight,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return 'Today at $hour:$minute';
    } else if (difference.inDays == 1) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return 'Yesterday at $hour:$minute';
    } else if (difference.inDays < 7) {
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = dayNames[date.weekday - 1];
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$dayName at $hour:$minute';
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day/$month/$year';
    }
  }
}
