import 'package:flutter/foundation.dart';
import 'dart:async';
import '../model/order_model.dart';
import '../service/order_service.dart';
import '../../../core/interfaces/state_clearable.dart';

class StoreOrderViewModel extends ChangeNotifier implements StateClearable {
  final OrderService _orderService = OrderService();

  List<Order> _orders = [];
  Map<String, int> _orderCounts = {};
  bool _isLoading = false;
  String? _error;
  OrderStatus? _currentFilter;
  StreamSubscription<List<Order>>? _ordersSubscription;

  List<Order> get orders => _orders;
  Map<String, int> get orderCounts => _orderCounts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  OrderStatus? get currentFilter => _currentFilter;

  List<Order> get filteredOrders {
    if (_currentFilter == null) {
      return _orders;
    }
    return _orders.where((order) => order.status == _currentFilter).toList();
  }

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

  Future<void> loadOrders() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _ordersSubscription?.cancel();

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

      await loadOrderCounts();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error in loadOrders: $e');
    }
  }

  Future<void> loadOrdersWithFilter(OrderStatus? status) async {
    try {
      _isLoading = true;
      _error = null;
      _currentFilter = status;
      notifyListeners();

      await _ordersSubscription?.cancel();

      if (status == null) {
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

  Future<void> refreshOrders() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final orders = await _orderService.getSellerOrdersFromServer();
      _orders = orders;

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

  Future<void> loadOrderCounts() async {
    try {
      final counts = await _orderService.getSellerOrdersCountByStatus();
      _orderCounts = counts;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading order counts: $e');
    }
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);

      await loadOrderCounts();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

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

  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  void clearFilter() {
    _currentFilter = null;
    loadOrders();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  Future<void> clearState() async {
    try {
      await _ordersSubscription?.cancel();
      _ordersSubscription = null;

      _orders = [];
      _orderCounts = {};
      _isLoading = false;
      _error = null;
      _currentFilter = null;

      notifyListeners();

      debugPrint('StoreOrderViewModel state cleared successfully');
    } catch (e) {
      debugPrint('Error clearing StoreOrderViewModel state: $e');
      _orders = [];
      _orderCounts = {};
      _isLoading = false;
      _error = null;
      _currentFilter = null;
      notifyListeners();
    }
  }
}
