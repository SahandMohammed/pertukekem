import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodel/customer_notification_viewmodel.dart';
import '../model/customer_notification_model.dart';
import 'notification_detail_screen.dart';

class CustomerNotificationListScreen extends StatefulWidget {
  const CustomerNotificationListScreen({super.key});

  @override
  State<CustomerNotificationListScreen> createState() =>
      _CustomerNotificationListScreenState();
}

class _CustomerNotificationListScreenState
    extends State<CustomerNotificationListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showOnlyUnread = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize notification viewmodel if not already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerNotificationViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        actions: [
          Consumer<CustomerNotificationViewModel>(
            builder: (context, viewModel, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'mark_all_read':
                      viewModel.markAllAsRead();
                      break;
                    case 'toggle_filter':
                      setState(() {
                        _showOnlyUnread = !_showOnlyUnread;
                      });
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'mark_all_read',
                        child: Row(
                          children: [
                            Icon(Icons.done_all, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            const Text('Mark all as read'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_filter',
                        child: Row(
                          children: [
                            Icon(
                              _showOnlyUnread
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _showOnlyUnread ? 'Show all' : 'Show unread only',
                            ),
                          ],
                        ),
                      ),
                    ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade600,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue.shade600,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Orders'),
            Tab(text: 'Books'),
            Tab(text: 'Offers'),
          ],
        ),
      ),
      body: Consumer<CustomerNotificationViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.error != null) {
            return _buildErrorWidget(viewModel);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(viewModel.notifications, viewModel),
              _buildNotificationList(viewModel.orderNotifications, viewModel),
              _buildNotificationList(viewModel.bookNotifications, viewModel),
              _buildNotificationList(
                viewModel.promotionalNotifications,
                viewModel,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(CustomerNotificationViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Error loading notifications',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.error!,
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              viewModel.clearError();
              viewModel.initialize();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
    List<CustomerNotification> notifications,
    CustomerNotificationViewModel viewModel,
  ) {
    List<CustomerNotification> filteredNotifications =
        _showOnlyUnread
            ? notifications.where((n) => !n.isRead).toList()
            : notifications;

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        viewModel.initialize();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          return _buildNotificationCard(notification, viewModel);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _showOnlyUnread
                ? 'No unread notifications'
                : 'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showOnlyUnread
                ? 'All caught up!'
                : 'We\'ll notify you when something happens',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    CustomerNotification notification,
    CustomerNotificationViewModel viewModel,
  ) {
    final isUnread = !notification.isRead;
    final createdAt = notification.createdAt.toDate();
    final timeAgo = _getTimeAgo(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnread ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isUnread
                ? BorderSide(color: Colors.blue.shade100, width: 1)
                : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isUnread) {
            viewModel.markAsRead(notification.id);
          }
          _navigateToNotificationDetail(notification);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isUnread ? Colors.blue.shade50 : Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(notification.colorValue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: Color(notification.colorValue),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight:
                                  isUnread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // More options
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'mark_read':
                      viewModel.markAsRead(notification.id);
                      break;
                    case 'delete':
                      _showDeleteConfirmation(notification, viewModel);
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      if (isUnread)
                        const PopupMenuItem(
                          value: 'mark_read',
                          child: Text('Mark as read'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(CustomerNotificationType type) {
    switch (type) {
      case CustomerNotificationType.orderConfirmed:
        return Icons.check_circle_outline;
      case CustomerNotificationType.orderShipped:
        return Icons.local_shipping_outlined;
      case CustomerNotificationType.orderDelivered:
        return Icons.home_outlined;
      case CustomerNotificationType.orderCancelled:
      case CustomerNotificationType.orderRefunded:
        return Icons.cancel_outlined;
      case CustomerNotificationType.newBookAvailable:
      case CustomerNotificationType.libraryUpdate:
        return Icons.book_outlined;
      case CustomerNotificationType.promotionalOffer:
        return Icons.local_offer_outlined;
      case CustomerNotificationType.paymentReminder:
        return Icons.payment_outlined;
      case CustomerNotificationType.systemUpdate:
        return Icons.info_outline;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat.yMMMd().format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _navigateToNotificationDetail(CustomerNotification notification) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NotificationDetailScreen(notification: notification),
      ),
    );
  }

  void _showDeleteConfirmation(
    CustomerNotification notification,
    CustomerNotificationViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Notification'),
            content: const Text(
              'Are you sure you want to delete this notification? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  viewModel.deleteNotification(notification.id);
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
