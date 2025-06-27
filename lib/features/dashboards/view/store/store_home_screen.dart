import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../service/dashboard_service.dart';
import '../../../notifications/service/unified_notification_service.dart';
import '../../../notifications/model/unified_notification_model.dart';
import 'notifications_screen.dart';
import '../../../orders/model/order_model.dart' as order_model;
import '../../../orders/service/order_service.dart';
import '../../../payments/view/store_transactions_screen.dart';

class DashboardHomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToOrders;

  const DashboardHomeScreen({super.key, this.onNavigateToOrders});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  final DashboardService _dashboardService = DashboardService();
  final UnifiedNotificationService _notificationService =
      UnifiedNotificationService();
  final OrderService _orderService = OrderService();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildRecentOrdersSection(),
              const SizedBox(height: 24),
              _buildNotificationsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_getGreeting()}!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s your store overview',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.store, size: 48, color: Colors.white.withOpacity(0.8)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return FutureBuilder<DashboardSummary>(
      future: _dashboardService.getDashboardSummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading dashboard: ${snapshot.error}'),
            ),
          );
        }

        final summary = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StoreTransactionsScreen(),
                      ),
                    );
                  },
                  child: _buildSummaryCard(
                    title: 'Total Revenue',
                    value: _currencyFormat.format(summary.totalRevenue),
                    icon: Icons.attach_money,
                    color: Colors.green,
                    subtitle: 'All time • Tap to view transactions',
                  ),
                ),
                _buildSummaryCard(
                  title: 'Monthly Revenue',
                  value: _currencyFormat.format(summary.monthlyRevenue),
                  icon: Icons.trending_up,
                  color: Colors.blue,
                  subtitle: 'This month',
                ),
                _buildSummaryCard(
                  title: 'Total Orders',
                  value: summary.totalOrders.toString(),
                  icon: Icons.shopping_cart,
                  color: Colors.orange,
                  subtitle: '${summary.pendingOrders} pending',
                ),
                _buildSummaryCard(
                  title: 'Active Listings',
                  value: summary.activeListings.toString(),
                  icon: Icons.inventory_2,
                  color: Colors.purple,
                  subtitle: '${summary.soldListings} sold',
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: 'Sales Report',
                subtitle: 'View your transactions',
                icon: Icons.receipt_long,
                color: Colors.green,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const StoreTransactionsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                title: 'Analytics',
                subtitle: 'Performance insights',
                icon: Icons.analytics,
                color: Colors.blue,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Analytics coming soon!')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    return StreamBuilder<List<order_model.Order>>(
      stream: _orderService.getSellerOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Orders',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        widget.onNavigateToOrders ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Navigate to Orders tab to see all orders',
                              ),
                            ),
                          );
                        },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Orders',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        widget.onNavigateToOrders ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Navigate to Orders tab to see all orders',
                              ),
                            ),
                          );
                        },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading orders: ${snapshot.error}'),
                ),
              ),
            ],
          );
        }

        final allOrders = snapshot.data ?? [];
        final recentOrders = allOrders.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Orders',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed:
                      widget.onNavigateToOrders ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Navigate to Orders tab to see all orders',
                            ),
                          ),
                        );
                      },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentOrders.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No orders yet',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...recentOrders.map((order) => _buildOrderCard(order)),
          ],
        );
      },
    );
  }

  Widget _buildOrderCard(order_model.Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order.status).withOpacity(0.1),
          child: Icon(
            _getStatusIcon(order.status),
            color: _getStatusColor(order.status),
          ),
        ),
        title: Text('Order #${order.id.substring(0, 8)}'),
        subtitle: Text(
          '${order.quantity} item(s) • ${DateFormat('MMM dd, yyyy').format(order.createdAt.toDate())}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _currencyFormat.format(order.totalAmount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(order.status),
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusColor(order.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Notifications',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<UnifiedNotification>>(
          stream: _notificationService.getStoreNotifications(limit: 5),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading notifications: ${snapshot.error}'),
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No notifications',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children:
                  notifications
                      .map(
                        (notification) => _buildNotificationCard(notification),
                      )
                      .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotificationCard(UnifiedNotification notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
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
        subtitle: Text(
          notification.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          DateFormat('MMM dd').format(notification.createdAt.toDate()),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () {
          if (!notification.isRead) {
            _notificationService.markAsRead(notification.id);
          }
        },
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Color _getStatusColor(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending:
        return Colors.orange;
      case order_model.OrderStatus.confirmed:
        return Colors.blue;
      case order_model.OrderStatus.shipped:
        return Colors.purple;
      case order_model.OrderStatus.delivered:
        return Colors.green;
      case order_model.OrderStatus.cancelled:
      case order_model.OrderStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending:
        return Icons.access_time;
      case order_model.OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case order_model.OrderStatus.shipped:
        return Icons.local_shipping;
      case order_model.OrderStatus.delivered:
        return Icons.check_circle;
      case order_model.OrderStatus.cancelled:
      case order_model.OrderStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getStatusText(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending:
        return 'Pending';
      case order_model.OrderStatus.confirmed:
        return 'Confirmed';
      case order_model.OrderStatus.shipped:
        return 'Shipped';
      case order_model.OrderStatus.delivered:
        return 'Delivered';
      case order_model.OrderStatus.cancelled:
        return 'Cancelled';
      case order_model.OrderStatus.rejected:
        return 'Rejected';
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return Colors.green;
      case NotificationType.orderCancelled:
        return Colors.red;
      case NotificationType.orderUpdate:
        return Colors.blue;
      case NotificationType.lowStock:
        return Colors.orange;
      case NotificationType.review:
        return Colors.purple;
      case NotificationType.system:
        return Colors.grey;
      default:
        return Colors.blue; // Default color for other notification types
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
      case NotificationType.lowStock:
        return Icons.inventory;
      case NotificationType.review:
        return Icons.star;
      case NotificationType.system:
        return Icons.info;
      default:
        return Icons.notifications; // Default icon for other notification types
    }
  }
}
