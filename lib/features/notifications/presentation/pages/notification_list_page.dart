// lib/features/notifications/presentation/pages/notification_list_page.dart

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mytuition/config/theme/app_colors.dart';
import 'package:mytuition/features/notifications/domain/notification_manager.dart';
import 'package:mytuition/features/notifications/domain/entities/notification.dart'
    as app_notification;
import 'package:mytuition/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:mytuition/core/utils/logger.dart';

enum SortOrder { newest, oldest }

SortOrder _currentSort = SortOrder.newest;

class NotificationListPage extends StatefulWidget {
  final String userId;

  const NotificationListPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  late NotificationManager _notificationManager;
  List<app_notification.Notification>? _notifications;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isMarkingAll = false;
  String? _notificationBeingMarkedAsRead;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreNotifications = true;
  final ScrollController _scrollController = ScrollController();

  // Filtering and sorting
  String? _currentFilter;

  @override
  void initState() {
    super.initState();
    // Get the notification manager and load notifications
    _notificationManager = GetIt.instance<NotificationManager>();
    _scrollController.addListener(_scrollListener);
    _loadNotifications();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreNotifications) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    log('Loading notifications for user: ${widget.userId}');
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _lastDocument = null;
      _hasMoreNotifications = true;
    });

    try {
      final result = await _notificationManager.getUserNotifications(
        widget.userId,
        filter: _currentFilter,
        sortDescending: _currentSort == SortOrder.newest,
      );

      if (mounted) {
        setState(() {
          _notifications = result.items;
          _lastDocument = result.lastDocument;
          _hasMoreNotifications = result.hasMore;
          _isLoading = false;
        });

        // Show feedback when manually refreshed
        if (mounted && _notifications != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications refreshed'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('Failed to load notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load notifications. Please try again.';
        });
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMoreNotifications || _lastDocument == null)
      return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _notificationManager.getUserNotifications(
        widget.userId,
        limit: 20,
        startAfter: _lastDocument,
        filter: _currentFilter,
        sortDescending: _currentSort == SortOrder.newest,
      );

      if (mounted) {
        setState(() {
          _notifications?.addAll(result.items);
          _lastDocument = result.lastDocument;
          _hasMoreNotifications = result.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      Logger.error('Failed to load more notifications: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      // Show loading indicator
      setState(() {
        _notificationBeingMarkedAsRead = notificationId;
      });

      await _notificationManager.markAsRead(notificationId);

      // Update local state
      if (mounted) {
        setState(() {
          _notifications = _notifications?.map((n) {
            if (n.id == notificationId) {
              return app_notification.Notification(
                id: n.id,
                userId: n.userId,
                type: n.type,
                title: n.title,
                message: n.message,
                isRead: true,
                createdAt: n.createdAt,
                readAt: DateTime.now(),
                data: n.data,
              );
            }
            return n;
          }).toList();
          _notificationBeingMarkedAsRead = null;
        });
      }
    } catch (e) {
      Logger.error('Error marking notification as read: $e');
      if (mounted) {
        setState(() {
          _notificationBeingMarkedAsRead = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Error marking notification as read. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAll) return; // Prevent multiple clicks

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark All as Read'),
        content: const Text(
            'Are you sure you want to mark all notifications as read?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Mark All as Read'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isMarkingAll = true;
    });

    try {
      // Optimistic UI update - save previous state for rollback if needed
      final previousNotifications = [...?_notifications];
      setState(() {
        _notifications = _notifications?.map((n) {
          return app_notification.Notification(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            message: n.message,
            isRead: true,
            createdAt: n.createdAt,
            readAt: DateTime.now(),
            data: n.data,
          );
        }).toList();
      });

      // Execute the actual operation
      final success = await _notificationManager.markAllAsRead(widget.userId);

      if (mounted) {
        setState(() {
          _isMarkingAll = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications marked as read'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Rollback optimistic update if failed
          setState(() {
            _notifications = previousNotifications;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Error marking notifications as read. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('Error marking all notifications as read: $e');
      if (mounted) {
        setState(() {
          _isMarkingAll = false;
        });
        _loadNotifications(); // Reload if error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Error marking notifications as read. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSortOrder() {
    setState(() {
      _currentSort = _currentSort == SortOrder.newest
          ? SortOrder.oldest
          : SortOrder.newest;
    });
    _loadNotifications();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Notifications'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption(null, 'All Notifications'),
              _buildFilterOption('payment_reminder', 'Payment Reminders'),
              _buildFilterOption('task_reminder', 'Task Reminders'),
              _buildFilterOption('tutor_notification', 'Tutor Notifications'),
              _buildFilterOption('class_announcement', 'Class Announcements'),
              // _buildFilterOption('test_notification', 'Test Notifications'),
            ],
          ),
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

  Widget _buildFilterOption(String? type, String label) {
    final isSelected = _currentFilter == type;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _currentFilter = type;
        });
        _loadNotifications();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryBlue : AppColors.textMedium,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected ? AppColors.primaryBlue : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentFilter == null
            ? 'Notifications'
            : 'Filtered Notifications'),
        actions: [
          // Filter button
          IconButton(
            icon: Icon(_currentFilter != null
                ? Icons.filter_list_alt
                : Icons.filter_list),
            tooltip: 'Filter',
            onPressed: _showFilterDialog,
          ),

          // Sort button
          IconButton(
            icon: Icon(_currentSort == SortOrder.newest
                ? Icons.arrow_downward
                : Icons.arrow_upward),
            tooltip: _currentSort == SortOrder.newest
                ? 'Newest first'
                : 'Oldest first',
            onPressed: _toggleSortOrder,
          ),

          // Mark all as read button
          if (_notifications != null &&
              _notifications!.isNotEmpty &&
              _notifications!.any((n) => !n.isRead))
            IconButton(
              icon: _isMarkingAll
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: _isMarkingAll ? null : _markAllAsRead,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return _buildErrorState(_errorMessage ?? 'An error occurred');
    }

    if (_notifications == null || _notifications!.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _notifications!.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _notifications!.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final notification = _notifications![index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'We couldn\'t load your notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'You\'ll see notifications here when they arrive';
    if (_currentFilter != null) {
      message = 'No notifications found with the selected filter';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: AppColors.textMedium),
            textAlign: TextAlign.center,
          ),
          if (_currentFilter != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentFilter = null;
                  });
                  _loadNotifications();
                },
                child: const Text('Show All Notifications'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(app_notification.Notification notification) {
    final isBeingMarkedAsRead =
        _notificationBeingMarkedAsRead == notification.id;
    final timeAgo = _getTimeAgo(notification.createdAt);

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: AppColors.primaryBlue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.done_all, color: Colors.white),
      ),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        // Mark as read
        await _markAsRead(notification.id);
        return false; // Don't actually dismiss
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: notification.isRead ? 0 : 2,
        color: notification.isRead
            ? Colors.white
            : AppColors.primaryBlueLight.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: notification.isRead
              ? BorderSide(color: AppColors.backgroundDark.withOpacity(0.5))
              : BorderSide(color: AppColors.primaryBlue.withOpacity(0.5)),
        ),
        child: InkWell(
          onTap: isBeingMarkedAsRead
              ? null
              : () async {
                  await _markAsRead(notification.id);

                  if (mounted) {
                    // Find the updated notification
                    final updatedNotification = _notifications!.firstWhere(
                      (n) => n.id == notification.id,
                      orElse: () => notification,
                    );

                    // Navigate to detail view
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationDetailPage(
                          notification:
                              updatedNotification.copyWith(isRead: true),
                        ),
                      ),
                    );
                  }
                },
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _getNotificationIcon(notification.type),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!notification.isRead && !isBeingMarkedAsRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: notification.isRead
                            ? AppColors.textMedium
                            : AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (isBeingMarkedAsRead)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'payment_reminder':
        iconData = Icons.account_balance_wallet;
        iconColor = AppColors.warning;
        break;
      case 'payment_confirmed':
        iconData = Icons.check_circle;
        iconColor = AppColors.success;
        break;
      case 'task_created':
      case 'task_reminder':
        iconData = Icons.assignment_late;
        iconColor = AppColors.warning;
        break;
      case 'task_feedback':
        iconData = Icons.rate_review;
        iconColor = AppColors.accentTeal;
        break;
      case 'tutor_notification':
        iconData = Icons.campaign;
        iconColor = AppColors.accentOrange;
        break;
      case 'class_announcement':
        iconData = Icons.school;
        iconColor = AppColors.primaryBlue;
        break;
      case 'test_notification':
        iconData = Icons.bug_report;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppColors.primaryBlue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 16,
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Today with time
    if (difference.inDays == 0) {
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      }
    }

    // Yesterday
    if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('h:mm a').format(dateTime)}';
    }

    // Within a week
    if (difference.inDays < 7) {
      return '${DateFormat('EEEE').format(dateTime)} at ${DateFormat('h:mm a').format(dateTime)}';
    }

    // Within this year
    if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime);
    }

    // Older
    return DateFormat('MMM d, yyyy').format(dateTime);
  }
}
