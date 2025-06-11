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

  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;

  OrderViewModel() {
    _initOrdersStream();
  }
  void _initOrdersStream() {
    try {
      _ordersStream = _orderService.getSellerOrders().handleError((error) {
        _errorMessage = error.toString();
        notifyListeners();
      });

      // Cancel existing subscription if any
      _ordersSubscription?.cancel();

      // Listen to the stream to detect errors early
      _ordersSubscription = _ordersStream?.listen(
        (orders) {
          // Stream is working, clear any previous errors
          if (_errorMessage != null) {
            _errorMessage = null;
            notifyListeners();
          }
        },
        onError: (error) {
          _errorMessage = error.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
    // Reinitialize the stream when clearing errors
    _initOrdersStream();
  }

  Stream<List<Order>> getOrders() {
    if (_ordersStream == null) {
      _initOrdersStream();
    }
    return _ordersStream ?? const Stream.empty();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _orderService.updateOrderStatus(orderId, newStatus);

      // Clear any previous error message on success
      _errorMessage = null;
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

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _errorMessage = null;
    _isLoading = false;
    _isRefreshing = false;
    super.dispose();
  }

  @override
  Future<void> clearState() async {
    debugPrint('🧹 Clearing OrderViewModel state...');

    // Cancel stream subscription to prevent infinite loops
    _ordersSubscription?.cancel();
    _ordersSubscription = null;

    // Clear all state
    _ordersStream = null;
    _errorMessage = null;
    _isLoading = false;
    _isRefreshing = false;

    // Notify listeners of state change
    notifyListeners();

    debugPrint('✅ OrderViewModel state cleared');
  }
}
