import 'package:flutter/material.dart';
import '../../../core/interfaces/state_clearable.dart';
import '../model/order_model.dart';
import '../service/order_service.dart';
import 'dart:async';

class CustomerOrdersViewModel extends ChangeNotifier implements StateClearable {
  final OrderService _orderService = OrderService();
  StreamSubscription<List<Order>>? _ordersSubscription;

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
    loadOrders();
  }

  Future<void> loadOrders() async {
    if (_disposed) return;

    try {
      _setLoading(true);
      _errorMessage = null;

      print('📱 Loading orders from server...');
      // Force fresh data from server to avoid cache issues
      _orders = await _orderService.getBuyerOrdersFromServer();

      if (_disposed) return; // Check again after async operation

      print('📦 Loaded ${_orders.length} orders from server');
      if (_orders.isNotEmpty) {
        print(
          '📋 Order IDs: ${_orders.map((o) => o.id.substring(0, 8)).join(', ')}',
        );
      }

      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      if (!_disposed) {
        _errorMessage = 'Failed to load orders: ${e.toString()}';
        print('❌ Error loading customer orders: $e');
        debugPrint('Error loading customer orders: $e');
      }
    } finally {
      if (!_disposed) {
        _setLoading(false);
      }
    }
  }

  Future<void> refreshOrders() async {
    if (_disposed) return;

    print('🔄 Starting order refresh...');

    try {
      // Force reload from server without cache
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
    notifyListeners();
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
    super.dispose();
  }

  @override
  Future<void> clearState() async {
    debugPrint('🧹 Clearing CustomerOrdersViewModel state...');

    // Cancel any active subscriptions
    _ordersSubscription?.cancel();
    _ordersSubscription = null;

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
}
