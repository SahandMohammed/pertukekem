import 'package:flutter/material.dart';
import '../../../core/interfaces/state_clearable.dart';
import '../../../core/services/order_sync_service.dart';
import '../model/order_model.dart';
import '../service/order_service.dart';
import 'dart:async';

class CustomerOrdersViewModel extends ChangeNotifier implements StateClearable {
  final OrderService _orderService = OrderService();
  final OrderSyncService _syncService = OrderSyncService();
  StreamSubscription<List<Order>>? _ordersSubscription;
  StreamSubscription<OrderUpdateEventBase>? _syncSubscription;

  List<Order> _orders = [];
  List<Order> get orders => _orders;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Filter options
  String _selectedStatus = 'all';
  String get selectedStatus => _selectedStatus;

  // Filtered orders based on status
  List<Order> get filteredOrders {
    if (_selectedStatus == 'all') {
      return _orders;
    }
    return _orders
        .where((order) => order.status.name == _selectedStatus)
        .toList();
  }

  // Order statistics
  int get totalOrders => _orders.length;
  int get pendingOrders =>
      _orders.where((order) => order.status == OrderStatus.pending).length;
  int get deliveredOrders =>
      _orders.where((order) => order.status == OrderStatus.delivered).length;
  int get cancelledOrders =>
      _orders.where((order) => order.status == OrderStatus.cancelled).length;

  double get totalSpent => _orders
      .where((order) => order.status == OrderStatus.delivered)
      .fold(0.0, (sum, order) => sum + order.totalAmount);
  bool _disposed = false;
  CustomerOrdersViewModel() {
    // Don't auto-load orders in constructor to avoid unnecessary calls
    // loadOrders() will be called when the UI is ready

    // Listen for external order updates (e.g., from store management)
    _syncSubscription = _syncService.orderUpdates.listen(
      (event) {
        if (_disposed) return;

        if (event is SingleOrderUpdateEvent) {
          print(
            '📢 Received order update notification: ${event.orderId} -> ${event.newStatus}',
          );
          // The real-time stream should automatically pick up this change,
          // but we can add additional logic here if needed
        } else if (event is BulkOrderUpdateEvent) {
          print(
            '📢 Received bulk order update notification: ${event.orderIds.length} orders',
          );
        }
      },
      onError: (error) {
        if (!_disposed) {
          print('❌ Error in sync stream: $error');
        }
      },
    );
  }
  Future<void> loadOrders() async {
    if (_disposed) return;

    try {
      _setLoading(true);
      _errorMessage = null;

      print('📱 Starting real-time orders stream...');

      // Cancel existing subscription if any
      await _ordersSubscription
          ?.cancel(); // Start listening to orders stream for real-time updates
      _ordersSubscription = _orderService.getBuyerOrders().listen(
        (orders) {
          if (_disposed) return;

          _orders = orders;
          print('📦 Received ${_orders.length} orders via real-time stream');
          if (_orders.isNotEmpty) {
            print(
              '📋 Order IDs: ${_orders.map((o) => o.id.substring(0, 8)).join(', ')}',
            );
            // Show the latest status for debugging
            print(
              '📊 Order statuses: ${_orders.map((o) => '${o.id.substring(0, 8)}:${o.status.name}').join(', ')}',
            );
          }

          // Orders are already sorted by createdAt desc from the query
          _setLoading(false);
        },
        onError: (error) {
          if (_disposed) return;

          _errorMessage = 'Failed to load orders: ${error.toString()}';
          print('❌ Error in orders stream: $error');
          debugPrint('Error in orders stream: $error');
          _setLoading(false);
        },
      );
    } catch (e) {
      if (!_disposed) {
        _errorMessage = 'Failed to load orders: ${e.toString()}';
        print('❌ Error setting up orders stream: $e');
        debugPrint('Error setting up orders stream: $e');
        _setLoading(false);
      }
    }
  }

  Future<void> refreshOrders() async {
    if (_disposed) return;

    print('🔄 Refreshing orders...');

    try {
      // Simply restart the stream to get fresh data
      await loadOrders();
      if (!_disposed) {
        print('✅ Order refresh completed');
      }
    } catch (e) {
      if (!_disposed) {
        print('❌ Order refresh failed: $e');
        _errorMessage = 'Failed to refresh orders: $e';
        notifyListeners();
      }
    }
  }

  void setStatusFilter(String status) {
    if (_disposed) return;
    _selectedStatus = status;
    notifyListeners();
  }

  void clearError() {
    if (_disposed) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_disposed) return;
    _isLoading = loading;
    if (!_disposed) {
      notifyListeners();
    }
  }

  // Static utility methods for status handling (to avoid creating instances)
  static Color getOrderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.rejected:
        return Colors.red.shade700;
    }
  }

  static IconData getOrderStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule_rounded;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.shipped:
        return Icons.local_shipping_rounded;
      case OrderStatus.delivered:
        return Icons.check_circle_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
      case OrderStatus.rejected:
        return Icons.block_rounded;
    }
  }

  static String getOrderStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }

  // Get order status color
  Color getStatusColor(OrderStatus status) => getOrderStatusColor(status);

  // Get order status icon
  IconData getStatusIcon(OrderStatus status) => getOrderStatusIcon(status);

  // Get user-friendly status text
  String getStatusText(OrderStatus status) => getOrderStatusText(status);
  // Debug method to check if data is coming from cache or server
  Future<void> debugOrderSource() async {
    if (_disposed) return;

    try {
      print('=== ORDER DEBUG INFO ===');

      // Check collection status first
      await _orderService.checkOrdersCollectionStatus();

      // Check cached orders count
      final ordersStream = _orderService.getBuyerOrders();
      await for (final ordersList in ordersStream.take(1)) {
        print('Cached orders count: ${ordersList.length}');
        if (ordersList.isNotEmpty) {
          print('First cached order ID: ${ordersList.first.id}');
        }
        break;
      }

      // Check server orders count
      final serverOrders = await _orderService.getBuyerOrdersFromServer();
      print('Server orders count: ${serverOrders.length}');
      if (serverOrders.isNotEmpty) {
        print('First server order ID: ${serverOrders.first.id}');
      }

      print('=== END DEBUG INFO ===');
    } catch (e) {
      print('Debug error: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing CustomerOrdersViewModel...');
    _disposed = true;
    _ordersSubscription?.cancel();
    _syncSubscription?.cancel();
    super.dispose();
  }

  @override
  Future<void> clearState() async {
    debugPrint('🧹 Clearing CustomerOrdersViewModel state...');

    // Cancel any active subscriptions
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
    _syncSubscription?.cancel();
    _syncSubscription = null;

    // Clear all state
    _orders.clear();
    _isLoading = false;
    _errorMessage = null;
    _selectedStatus = 'all';

    // Notify listeners only if not disposed
    if (!_disposed) {
      notifyListeners();
    }

    debugPrint('✅ CustomerOrdersViewModel state cleared');
  }

  /// Force reconnect the orders stream (for debugging/troubleshooting)
  Future<void> reconnectStream() async {
    if (_disposed) return;

    print('🔄 Reconnecting orders stream...');
    await _ordersSubscription?.cancel();
    await loadOrders();
  }
}
