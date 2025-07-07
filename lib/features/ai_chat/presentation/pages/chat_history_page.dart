// features/ai_chat/presentation/pages/chat_history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:sizer/sizer.dart';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2.5.h)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(2.5.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(0.25.h),
              ),
            ),
            SizedBox(height: 2.5.h),
            Text(
              'Chat Session Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
            ),
            SizedBox(height: 2.5.h),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(1.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(1.h),
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: AppColors.primaryBlue,
                  size: 2.5.h,
                ),
              ),
              title: Text(
                'Resume Chat',
                style: TextStyle(fontSize: 14.sp),
              ),
              subtitle: Text(
                'Continue this conversation',
                style: TextStyle(fontSize: 14.sp),
              ),
              onTap: () {
                Navigator.pop(context);
                _resumeSession(session);
              },
            ),
            SizedBox(height: 1.h),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(1.h),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(1.h),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 2.5.h,
                ),
              ),
              title: Text(
                'Delete Session',
                style: TextStyle(fontSize: 14.sp),
              ),
              subtitle: Text(
                'Permanently remove this chat',
                style: TextStyle(fontSize: 14.sp),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteSession(session);
              },
            ),
            SizedBox(height: 2.5.h),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryBlue),
          SizedBox(height: 2.h),
          Text(
            'Loading chat history...',
            style: TextStyle(
              color: AppColors.textMedium,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(2.h),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 6.h,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Failed to Load History',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
            ),
            SizedBox(height: 1.5.h),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 11.sp,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () {
                context.read<ChatHistoryBloc>().add(
                      LoadArchivedSessionsEvent(widget.studentId),
                    );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              ),
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
        padding: EdgeInsets.all(2.h),
        itemCount: state.archivedSessions.length,
        separatorBuilder: (context, index) => SizedBox(height: 1.5.h),
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
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(3.h),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 6.h,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'No Chat History Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
            ),
            SizedBox(height: 1.5.h),
            Text(
              'Your previous conversations will appear here when you start new chat sessions.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMedium,
                    fontSize: 15.sp,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.chat),
              label: const Text('Start Chatting'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(ChatSession session) {
    // Check if session might be expired (older than 60 days)
    final daysSinceActive =
        DateTime.now().difference(session.lastActive).inDays;
    final mightBeExpired = daysSinceActive > 60;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(1.5.h),
      ),
      child: InkWell(
        onTap: () => _showSessionActions(session),
        borderRadius: BorderRadius.circular(1.5.h),
        child: Padding(
          padding: EdgeInsets.all(2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(1.h),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(1.h),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.primaryBlue,
                      size: 2.5.h,
                    ),
                  ),
                  SizedBox(width: 1.5.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat Session',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15.sp,
                                  ),
                        ),
                        Text(
                          _formatDate(session.lastActive),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMedium,
                                    fontSize: 14.sp,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.more_vert,
                    color: AppColors.textLight,
                    size: 2.5.h,
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),
              Wrap(
                spacing: 1.w,
                runSpacing: 0.5.h,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(0.75.h),
                    ),
                    child: Text(
                      '${session.messageCount} messages',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMedium,
                            fontSize: 13.sp,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(0.75.h),
                    ),
                    child: Text(
                      'Archived',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.accentTeal,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                    ),
                  ),
                  if (mightBeExpired) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 1.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(0.75.h),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 1.5.h,
                            color: AppColors.warning,
                          ),
                          SizedBox(width: 0.5.w),
                          Text(
                            'May be expired',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 8.sp,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                mightBeExpired
                    ? 'Old session - might need new chat if expired'
                    : 'Tap to resume or manage this conversation',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textLight,
                      fontStyle: FontStyle.italic,
                      fontSize: 15.sp,
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
