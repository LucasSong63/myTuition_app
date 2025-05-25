import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/chat_message.dart';
import '../../../../config/theme/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == ChatMessageType.user;
    final isLoading = message.isLoading;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: EdgeInsets.only(
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildMessageBubble(context, isUser, isLoading),
            const SizedBox(height: 4),
            _buildTimestamp(context, isUser),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
      BuildContext context, bool isUser, bool isLoading) {
    return GestureDetector(
      onLongPress: () => _showCopyOption(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryBlue : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: isUser ? null : Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              _buildAvatarIcon(),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser && !isLoading)
                    Text(
                      'AI Tutor',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  if (!isUser && !isLoading) const SizedBox(height: 4),
                  isLoading
                      ? _buildLoadingIndicator()
                      : _buildMessageText(context, isUser),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.psychology,
        size: 14,
        color: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primaryBlue.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Thinking...',
          style: TextStyle(
            color: AppColors.textMedium,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageText(BuildContext context, bool isUser) {
    return SelectableText(
      message.content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: isUser ? AppColors.white : AppColors.textDark,
        height: 1.4,
        // FIXED: Add emoji font fallback for better compatibility
        fontFamilyFallback: const [
          'Apple Color Emoji', // iOS
          'Segoe UI Emoji', // Windows
          'Noto Color Emoji', // Android
          'Noto Emoji', // Android fallback
          'Symbola', // Linux
        ],
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context, bool isUser) {
    final timeString = _formatTime(message.timestamp);

    return Text(
      timeString,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textLight,
            fontSize: 10,
          ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Today: show time only
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      // Other days: show date and time
      final day = timestamp.day.toString().padLeft(2, '0');
      final month = timestamp.month.toString().padLeft(2, '0');
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '$day/$month $hour:$minute';
    }
  }

  void _showCopyOption(BuildContext context) {
    if (message.isLoading) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
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
            ListTile(
              leading: const Icon(Icons.copy, color: AppColors.primaryBlue),
              title: const Text('Copy message'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
