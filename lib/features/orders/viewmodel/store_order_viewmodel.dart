import 'package:flutter/foundation.dart';
import 'dart:async';
import '../model/order_model.dart';
import '../service/order_service.dart';
import '../../../core/interfaces/state_clearable.dart';

class StoreOrderViewModel extends ChangeNotifier implements StateClearable {
  final OrderService _orderService = OrderService();

  // State
  List<Order> _orders = [];
  Map<String, int> _orderCounts = {};
  bool _isLoading = false;
  String? _error;
  OrderStatus? _currentFilter;
  StreamSubscription<List<Order>>? _ordersSubscription;

  // Getters
  List<Order> get orders => _orders;
  Map<String, int> get orderCounts => _orderCounts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  OrderStatus? get currentFilter => _currentFilter;

  // Get filtered orders based on current filter
  List<Order> get filteredOrders {
    if (_currentFilter == null) {
      return _orders;
    }
    return _orders.where((order) => order.status == _currentFilter).toList();
  }

  // Get orders count for specific status
  int getOrdersCount(String status) {
    if (status == 'all') {
      return _orderCounts['all'] ?? 0;
    }
    return _orderCounts[status] ?? 0;
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  /// Load all orders for the current store
  Future<void> loadOrders() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Cancel existing subscription
      await _ordersSubscription?.cancel();

      // Start listening to orders stream
      _ordersSubscription = _orderService.getSellerOrders().listen(
        (orders) {
          _orders = orders;
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (error) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
          debugPrint('Error loading orders: $error');
        },
      );

      // Load order counts
      await loadOrderCounts();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error in loadOrders: $e');
    }
  }

  /// Load orders with a specific status filter
  Future<void> loadOrdersWithFilter(OrderStatus? status) async {
    try {
      _isLoading = true;
      _error = null;
      _currentFilter = status;
      notifyListeners();

      // Cancel existing subscription
      await _ordersSubscription?.cancel();

      if (status == null) {
        // Load all orders
        _ordersSubscription = _orderService.getSellerOrders().listen(
          (orders) {
            _orders = orders;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
            debugPrint('Error loading orders: $error');
          },
        );
      } else {
        // Load orders with specific status
        _ordersSubscription = _orderService
            .getSellerOrdersByStatus(status)
            .listen(
              (orders) {
                _orders = orders;
                _isLoading = false;
                _error = null;
                notifyListeners();
              },
              onError: (error) {
                _error = error.toString();
                _isLoading = false;
                notifyListeners();
                debugPrint('Error loading filtered orders: $error');
              },
            );
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error in loadOrdersWithFilter: $e');
    }
  }

  /// Force refresh orders from server
  Future<void> refreshOrders() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final orders = await _orderService.getSellerOrdersFromServer();
      _orders = orders;

      // Also refresh counts
      await loadOrderCounts();

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error refreshing orders: $e');
    }
  }

  /// Load order counts by status
  Future<void> loadOrderCounts() async {
    try {
      final counts = await _orderService.getSellerOrdersCountByStatus();
      _orderCounts = counts;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading order counts: $e');
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);

      // Refresh counts after status update
      await loadOrderCounts();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  /// Update tracking number
  Future<bool> updateTrackingNumber(
    String orderId,
    String trackingNumber,
  ) async {
    try {
      await _orderService.updateTrackingNumber(orderId, trackingNumber);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error updating tracking number: $e');
      return false;
    }
  }

  /// Get order by ID
  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  /// Clear filter and show all orders
  void clearFilter() {
    _currentFilter = null;
    loadOrders();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all state, cancel subscriptions, and reset to initial state
  @override
  Future<void> clearState() async {
    try {
      // Cancel any active subscriptions
      await _ordersSubscription?.cancel();
      _ordersSubscription = null;

      // Reset all state variables to their initial values
      _orders = [];
      _orderCounts = {};
      _isLoading = false;
      _error = null;
      _currentFilter = null;

      // Notify listeners of the state change
      notifyListeners();

      debugPrint('StoreOrderViewModel state cleared successfully');
    } catch (e) {
      debugPrint('Error clearing StoreOrderViewModel state: $e');
      // Still reset the state even if there was an error
      _orders = [];
      _orderCounts = {};
      _isLoading = false;
      _error = null;
      _currentFilter = null;
      notifyListeners();
    }
  }
}
