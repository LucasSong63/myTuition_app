// features/ai_chat/presentation/widgets/chat_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mytuition/main.dart';
import 'package:sizer/sizer.dart';
import '../../../../config/theme/app_colors.dart';
import '../pages/chat_history_page.dart';
import '../bloc/chat_history_bloc.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? studentId;
  final VoidCallback? onNewSession;
  final VoidCallback? onShowHistory;

  const ChatAppBar({
    Key? key,
    required this.title,
    this.studentId,
    this.onNewSession,
    this.onShowHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 1.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlueDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        // FIXED: Remove default status bar handling since we're doing it manually
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Row(
          children: [
            // AI Status Indicator
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Status Dot
                  _buildStatusIndicator(),
                  const SizedBox(width: 8),
                  // AI Icon
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Title and Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Online • Ready to help',
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // History Button
          if (studentId != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Material(
                color: AppColors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider<ChatHistoryBloc>(
                          create: (context) => getIt<ChatHistoryBloc>(),
                          child: ChatHistoryPage(studentId: studentId!),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.history,
                      color: AppColors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

          // New Session Button (if provided)
          if (onNewSession != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Material(
                color: AppColors.accentOrange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onNewSession,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_comment_outlined,
                          color: AppColors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'New',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.success.withOpacity(0.6),
              AppColors.success,
              value,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: value * 2,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight +
      MediaQueryData.fromView(WidgetsBinding.instance.window).padding.top);
}
