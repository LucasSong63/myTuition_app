// lib/features/notifications/presentation/widgets/notification_badge.dart

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/notifications/domain/notification_manager.dart';
import 'package:mytuition/core/utils/logger.dart';

class NotificationBadge extends StatefulWidget {
  final String userId;
  final Color badgeColor;
  final Color iconColor;
  final VoidCallback onTap;
  final double? iconSize;
  final String? semanticsLabel;

  const NotificationBadge({
    Key? key,
    required this.userId,
    this.badgeColor = AppColors.error,
    this.iconColor = Colors.white,
    required this.onTap,
    this.iconSize,
    this.semanticsLabel,
  }) : super(key: key);

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _getUnreadCountStream(),
      initialData: 0,
      builder: (context, snapshot) {
        int count = snapshot.data ?? 0;
        return _buildBadge(context, count);
      },
    );
  }

  Stream<int> _getUnreadCountStream() {
    try {
      // Try to get the NotificationManager from GetIt
      if (GetIt.instance.isRegistered<NotificationManager>()) {
        final manager = GetIt.instance<NotificationManager>();
        return manager.getUnreadCountStream(widget.userId);
      }

      // If not found, return empty stream with 0
      return Stream.value(0);
    } catch (e) {
      Logger.error('Error getting unread count stream: $e');
      return Stream.value(0);
    }
  }

  Widget _buildBadge(BuildContext context, int count) {
    // Default icon size
    final defaultIconSize = widget.iconSize ?? 24.0;
    // Min badge size
    final minBadgeSize = 16.0;

    return Semantics(
      label: widget.semanticsLabel ??
          'Notifications, ${count > 0 ? '$count unread' : 'no unread'}',
      button: true,
      child: Stack(
        children: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, size: defaultIconSize),
            onPressed: widget.onTap,
            color: widget.iconColor,
            tooltip: 'Notifications ${count > 0 ? "($count)" : ""}',
          ),
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: count > 9
                    ? const EdgeInsets.all(2)
                    : const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.badgeColor,
                  shape: count > 9 ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: count > 9 ? BorderRadius.circular(8) : null,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: BoxConstraints(
                  minWidth: minBadgeSize,
                  minHeight: minBadgeSize,
                ),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: count > 9 ? 8 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
