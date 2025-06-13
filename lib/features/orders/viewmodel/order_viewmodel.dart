import 'package:flutter/material.dart';
import '../../../core/interfaces/state_clearable.dart';
import '../model/order_model.dart';
import '../service/order_service.dart';
import 'dart:async';

class OrderViewModel extends ChangeNotifier implements StateClearable {
  final OrderService _orderService = OrderService();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isRefreshing = false;
  Stream<List<Order>>? _ordersStream;
  StreamSubscription<List<Order>>? _ordersSubscription;
  Timer? _autoRefreshTimer;
  bool _autoRefreshEnabled = true;

  // Filter state management
  String _selectedFilter = 'all';
  String get selectedFilter => _selectedFilter;

  // UI state management
  String? _successMessage;
  String? get successMessage => _successMessage;

  // Getters
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get autoRefreshEnabled => _autoRefreshEnabled;

  List<String> get availableFilters => [
    'all',
    'pending',
    'confirmed',
    'shipped',
    'delivered',
    'cancelled',
    'rejected',
  ];

  Map<String, dynamic> getFilterConfig(String key) {
    final configs = {
      'all': {'label': 'All', 'icon': Icons.all_inclusive},
      'pending': {'label': 'Pending', 'icon': Icons.schedule_outlined},
      'confirmed': {'label': 'Confirmed', 'icon': Icons.check_circle_outline},
      'shipped': {'label': 'Shipped', 'icon': Icons.local_shipping_outlined},
      'delivered': {'label': 'Delivered', 'icon': Icons.done_all},
      'cancelled': {'label': 'Cancelled', 'icon': Icons.cancel_outlined},
      'rejected': {'label': 'Rejected', 'icon': Icons.close_rounded},
    };
    return configs[key] ?? {'label': key, 'icon': Icons.help_outline};
  }

  OrderViewModel() {
    _initOrdersStream();
    _startAutoRefresh();
  }
  void _startAutoRefresh() {
    // Auto-refresh every 30 seconds to check for new orders
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_autoRefreshEnabled && !_isRefreshing && _errorMessage == null) {
        debugPrint('🔄 Auto-refreshing orders...');
        refreshOrders();
      }
    });
  }

  void toggleAutoRefresh() {
    _autoRefreshEnabled = !_autoRefreshEnabled;
    debugPrint(
      '🔄 Auto-refresh ${_autoRefreshEnabled ? 'enabled' : 'disabled'}',
    );
    notifyListeners();
  }

  void _initOrdersStream() {
    try {
      _isLoading = true;
      _errorMessage = null; // Clear any previous errors
      notifyListeners();

      debugPrint('🚀 Initializing orders stream...');

      _ordersStream = _orderService.getSellerOrders().handleError((error) {
        debugPrint('❌ Orders stream error: $error');
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      });

      // Cancel existing subscription if any
      _ordersSubscription?.cancel();

      // Listen to the stream to detect errors early and manage loading state
      _ordersSubscription = _ordersStream?.listen(
        (orders) {
          // Stream is working, clear any previous errors and loading state
          if (_errorMessage != null) {
            _errorMessage = null;
          }
          _isLoading = false;
          debugPrint('✅ Orders loaded: ${orders.length} orders');
          notifyListeners();
        },
        onError: (error) {
          debugPrint('❌ Orders subscription error: $error');
          _errorMessage = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('❌ Error initializing orders stream: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
    // Reinitialize the stream when clearing errors
    _initOrdersStream();
  }

  // Clear service cache and reinitialize - useful for performance
  void clearCacheAndRefresh() {
    debugPrint('🧹 Clearing cache and refreshing orders...');
    _orderService.clearCache();
    _initOrdersStream();
  }

  Stream<List<Order>> getOrders() {
    if (_ordersStream == null) {
      _initOrdersStream();
    }
    return _ordersStream ?? const Stream.empty();
  }

  Future<void> refreshOrders() async {
    // Prevent multiple simultaneous refresh operations
    if (_isRefreshing) {
      debugPrint('⏳ Refresh already in progress, skipping...');
      return;
    }

    try {
      _isRefreshing = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('🔄 Refreshing orders...');

      // For a more efficient refresh, just reinitialize the stream
      // The cache will be used if available, making it faster
      _initOrdersStream();

      debugPrint('✅ Order refresh initiated');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ Error refreshing orders: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _orderService.updateOrderStatus(orderId, newStatus);

      // Clear any previous error message on success
      _errorMessage = null;

      // Refresh the orders stream to get updated data
      await refreshOrders();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTrackingNumber(
    String orderId,
    String trackingNumber,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _orderService.updateTrackingNumber(orderId, trackingNumber);

      // Clear any previous error message on success
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Debug and fix order reference issues
  Future<void> debugAndFixOrderIssues() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('🔧 Starting order debugging and fixing...');

      // First debug to identify issues
      await _orderService.debugOrderReferences();

      // Then attempt to fix them
      await _orderService.fixOrderReferences();

      // Clear error and reinitialize stream to get fresh data
      _errorMessage = null;
      _initOrdersStream();

      print('✅ Order debugging and fixing completed!');
    } catch (e) {
      _errorMessage = 'Debug/Fix failed: ${e.toString()}';
      print('❌ Debug/Fix error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if store exists for current user
  Future<bool> checkStoreExists() async {
    try {
      return await _orderService.checkStoreExists();
    } catch (e) {
      print('Error checking store: $e');
      return false;
    }
  }

  // Filter management methods
  void setFilter(String filter) {
    if (availableFilters.contains(filter)) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  List<Order> filterOrders(List<Order> orders) {
    if (_selectedFilter == 'all') return orders;
    return orders
        .where((order) => order.status.name == _selectedFilter)
        .toList();
  }

  // UI state management methods
  void clearMessages() {
    _successMessage = null;
    _errorMessage = null;
    notifyListeners();
  }

  void showSuccess(String message) {
    _successMessage = message;
    notifyListeners();
    // Auto-clear success message after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (_successMessage == message) {
        _successMessage = null;
        notifyListeners();
      }
    });
  }

  // Status update with feedback
  Future<void> updateOrderStatusWithFeedback(
    String orderId,
    OrderStatus newStatus, {
    String? customMessage,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _orderService.updateOrderStatus(orderId, newStatus);

      // Show success message
      final statusText = getStatusText(newStatus);
      showSuccess(customMessage ?? 'Order status updated to $statusText');

      // Refresh the orders stream to get updated data
      await refreshOrders();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods for UI
  String getStatusText(OrderStatus status) {
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

  IconData getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule_outlined;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.shipped:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
      case OrderStatus.rejected:
        return Icons.close_rounded;
    }
  }

  Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange.shade600;
      case OrderStatus.confirmed:
        return Colors.blue.shade600;
      case OrderStatus.shipped:
        return Colors.indigo.shade600;
      case OrderStatus.delivered:
        return Colors.green.shade600;
      case OrderStatus.cancelled:
        return Colors.red.shade600;
      case OrderStatus.rejected:
        return Colors.red.shade700;
    }
  }

  // Navigation helpers
  void navigateToOrderDetails(BuildContext context, Order order) {
    Navigator.of(context).pushNamed('/order-details', arguments: order);
  }

  bool get shouldShowEmptyState => _selectedFilter != 'all';

  String get emptyStateTitle =>
      _selectedFilter == 'all'
          ? 'No Orders Yet'
          : 'No ${_selectedFilter.toUpperCase()} Orders';

  String get emptyStateMessage =>
      _selectedFilter == 'all'
          ? 'Orders from customers will appear here'
          : 'No orders with $_selectedFilter status found';

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _autoRefreshTimer?.cancel();
    _errorMessage = null;
    _isLoading = false;
    _isRefreshing = false;
    super.dispose();
  }

  @override
  Future<void> clearState() async {
    debugPrint('🧹 Clearing OrderViewModel state...');

    // Cancel stream subscription and auto-refresh timer
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;

    // Clear service cache for better performance on next init
    _orderService.clearCache();

    // Clear all state
    _ordersStream = null;
    _errorMessage = null;
    _successMessage = null;
    _isLoading = false;
    _isRefreshing = false;
    _selectedFilter = 'all';

    // Notify listeners of state change
    notifyListeners();

    debugPrint('✅ OrderViewModel state cleared');
  }
}
