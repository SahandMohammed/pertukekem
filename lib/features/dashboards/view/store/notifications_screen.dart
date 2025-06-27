import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../notifications/service/unified_notification_service.dart';
import '../../../notifications/model/unified_notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final UnifiedNotificationService _notificationService =
      UnifiedNotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              _markAllAsRead();
            },
            child: const Text('Mark All Read'),
          ),
        ],
      ),
      body: StreamBuilder<List<UnifiedNotification>>(
        stream: _notificationService.getStoreNotifications(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see new orders, updates, and important announcements here.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(UnifiedNotification notification) {
    return Card(
      elevation: notification.isRead ? 1 : 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border:
              notification.isRead
                  ? null
                  : Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: _getNotificationColor(
              notification.type,
            ).withOpacity(0.1),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatNotificationTime(notification.createdAt.toDate()),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
          onTap: () {
            if (!notification.isRead) {
              _markAsRead(notification.id);
            }
            _handleNotificationTap(notification);
          },
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return Colors.green;
      case NotificationType.orderCancelled:
        return Colors.red;
      case NotificationType.orderUpdate:
        return Colors.blue;
      case NotificationType.orderConfirmed:
        return Colors.green;
      case NotificationType.orderShipped:
        return Colors.blue;
      case NotificationType.orderDelivered:
        return Colors.green;
      case NotificationType.orderRefunded:
        return Colors.orange;
      case NotificationType.newBookAvailable:
        return Colors.purple;
      case NotificationType.promotionalOffer:
        return Colors.amber;
      case NotificationType.systemUpdate:
        return Colors.grey;
      case NotificationType.libraryUpdate:
        return Colors.indigo;
      case NotificationType.paymentReminder:
        return Colors.red;
      case NotificationType.lowStock:
        return Colors.orange;
      case NotificationType.review:
        return Colors.purple;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return Icons.shopping_cart;
      case NotificationType.orderCancelled:
        return Icons.cancel;
      case NotificationType.orderUpdate:
        return Icons.update;
      case NotificationType.orderConfirmed:
        return Icons.check_circle;
      case NotificationType.orderShipped:
        return Icons.local_shipping;
      case NotificationType.orderDelivered:
        return Icons.done_all;
      case NotificationType.orderRefunded:
        return Icons.money_off;
      case NotificationType.newBookAvailable:
        return Icons.library_books;
      case NotificationType.promotionalOffer:
        return Icons.local_offer;
      case NotificationType.systemUpdate:
        return Icons.system_update;
      case NotificationType.libraryUpdate:
        return Icons.library_add;
      case NotificationType.paymentReminder:
        return Icons.payment;
      case NotificationType.lowStock:
        return Icons.inventory;
      case NotificationType.review:
        return Icons.star;
      case NotificationType.system:
        return Icons.info;
    }
  }

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  }

  void _markAsRead(String notificationId) {
    _notificationService.markAsRead(notificationId);
  }

  void _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead(
        target: NotificationTarget.store,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking notifications as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleNotificationTap(UnifiedNotification notification) {
    switch (notification.type) {
      case NotificationType.newOrder:
      case NotificationType.orderUpdate:
      case NotificationType.orderCancelled:
      case NotificationType.orderConfirmed:
      case NotificationType.orderShipped:
      case NotificationType.orderDelivered:
      case NotificationType.orderRefunded:
        Navigator.of(context).pop(); // Close notifications screen
        break;
      case NotificationType.lowStock:
        Navigator.of(context).pop();
        break;
      case NotificationType.review:
        break;
      case NotificationType.system:
      case NotificationType.systemUpdate:
        break;
      case NotificationType.newBookAvailable:
      case NotificationType.libraryUpdate:
        break;
      case NotificationType.promotionalOffer:
        break;
      case NotificationType.paymentReminder:
        break;
    }
  }
}
