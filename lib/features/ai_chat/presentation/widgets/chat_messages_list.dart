// features/ai_chat/presentation/widgets/chat_messages_list.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../domain/entities/chat_message.dart';
import 'message_bubble.dart';
import '../../../../config/theme/app_colors.dart';

class ChatMessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;

  const ChatMessagesList({
    Key? key,
    required this.messages,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return _buildEmptyState(context);
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Handle keyboard
      ),
      child: ListView.separated(
        controller: scrollController,
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        itemCount: messages.length,
        separatorBuilder: (context, index) => SizedBox(height: 1.5.h),
        itemBuilder: (context, index) {
          final message = messages[index];
          return MessageBubble(message: message);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // Get screen height and keyboard height
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight =
        screenHeight - keyboardHeight - 25.h; // Subtract app bar and input

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: availableHeight > 50.h ? availableHeight : 50.h,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.5.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // AI Avatar
              Container(
                padding: EdgeInsets.all(3.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    width: 0.25.w,
                  ),
                ),
                child: Icon(
                  Icons.psychology,
                  size: 6.h,
                  color: AppColors.primaryBlue,
                ),
              ),

              SizedBox(height: 3.h),

              // Greeting
              Text(
                'Hi there! 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 1.h),

              Text(
                'I\'m your AI tutor, ready to help!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryBlue,
                      fontSize: 14.sp,
                    ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 3.h),

              // Capabilities Card
              Container(
                padding: EdgeInsets.all(2.5.h),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(2.h),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.accentOrange,
                          size: 2.5.h,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'I can help you with:',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                    fontSize: 14.sp,
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    ..._buildHelpItems(context),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              // Call to Action
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentTeal.withOpacity(0.1),
                      AppColors.primaryBlue.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3.h),
                  border: Border.all(
                    color: AppColors.accentTeal.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.psychology,
                      color: AppColors.accentTeal,
                      size: 2.5.h,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Ask me anything! 💡',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.accentTeal,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                    ),
                  ],
                ),
              ),

              // Add some bottom space to prevent overflow
              SizedBox(height: keyboardHeight > 0 ? 2.5.h : 5.h),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHelpItems(BuildContext context) {
    final items = [
      ('📚', 'Math, Science, English'),
      ('🇲🇾', 'Bahasa Malaysia'),
      ('🇨🇳', 'Chinese language'),
      ('📝', 'Homework help'),
      ('📅', 'Study planning'),
    ];

    return items
        .map((item) => Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                children: [
                  Text(
                    item.$1,
                    style: TextStyle(fontSize: 13.sp),
                  ),
                  SizedBox(width: 1.5.w),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMedium,
                            fontSize: 14.sp,
                          ),
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }
}
