// features/ai_chat/presentation/widgets/chat_messages_list.dart
import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: messages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
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
        screenHeight - keyboardHeight - 200; // Subtract app bar and input

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: availableHeight > 400 ? availableHeight : 400,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // AI Avatar
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 48,
                  color: AppColors.primaryBlue,
                ),
              ),

              const SizedBox(height: 24),

              // Greeting
              Text(
                'Hi there! 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'I\'m your AI tutor, ready to help!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Capabilities Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
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
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'I can help you with:',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._buildHelpItems(context),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Call to Action
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentTeal.withOpacity(0.1),
                      AppColors.primaryBlue.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
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
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ask me anything! 💡',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.accentTeal,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),

              // Add some bottom space to prevent overflow
              SizedBox(height: keyboardHeight > 0 ? 20 : 40),
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
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    item.$1,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMedium,
                          ),
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }
}
