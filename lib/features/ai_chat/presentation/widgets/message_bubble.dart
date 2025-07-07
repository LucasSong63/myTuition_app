import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
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
          maxWidth: 80.w, // Responsive max width
        ),
        margin: EdgeInsets.only(
          left: isUser ? 12.w : 0, // Responsive margins
          right: isUser ? 0 : 12.w,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildMessageBubble(context, isUser, isLoading),
            SizedBox(height: 0.5.h),
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
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryBlue : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(2.5.h),
            topRight: Radius.circular(2.5.h),
            bottomLeft: Radius.circular(isUser ? 2.5.h : 0.5.h),
            bottomRight: Radius.circular(isUser ? 0.5.h : 2.5.h),
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
              SizedBox(width: 1.w),
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
                            fontSize: 14.sp,
                          ),
                    ),
                  if (!isUser && !isLoading) SizedBox(height: 0.5.h),
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
      width: 3.h,
      height: 3.h,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.psychology,
        size: 1.75.h,
        color: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 2.h,
          height: 2.h,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primaryBlue.withOpacity(0.6),
            ),
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          'Thinking...',
          style: TextStyle(
            color: AppColors.textMedium,
            fontSize: 10.sp,
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
        fontSize: 15.sp,
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
            fontSize: 8.sp,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2.h)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(2.h),
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
            ListTile(
              leading:
                  Icon(Icons.copy, color: AppColors.primaryBlue, size: 3.h),
              title: Text('Copy message', style: TextStyle(fontSize: 12.sp)),
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
