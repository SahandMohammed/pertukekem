import 'package:flutter/material.dart';
import '../model/order_model.dart';
import '../service/order_service.dart';

class OrderViewModel extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isRefreshing = false;
  Stream<List<Order>>? _ordersStream;

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

  @override
  void dispose() {
    _errorMessage = null;
    _isLoading = false;
    _isRefreshing = false;
    super.dispose();
  }
}
