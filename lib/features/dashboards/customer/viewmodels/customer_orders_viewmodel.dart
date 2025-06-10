import 'package:flutter/material.dart';
import '../../../orders/model/order_model.dart';
import '../../../orders/service/order_service.dart';

class CustomerOrdersViewModel extends ChangeNotifier {
  final OrderService _orderService = OrderService();

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

  CustomerOrdersViewModel() {
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      // Use the existing getBuyerOrders stream and convert to list
      final ordersStream = _orderService.getBuyerOrders();
      await for (final ordersList in ordersStream.take(1)) {
        _orders = ordersList;
        break;
      }

      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load orders: ${e.toString()}';
      debugPrint('Error loading customer orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshOrders() async {
    await loadOrders();
  }

  void setStatusFilter(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get order status color
  Color getStatusColor(OrderStatus status) {
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

  // Get order status icon
  IconData getStatusIcon(OrderStatus status) {
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

  // Get user-friendly status text
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

  @override
  void dispose() {
    super.dispose();
  }
}
