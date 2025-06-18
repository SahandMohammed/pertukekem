import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service to coordinate order updates across different parts of the app
/// This ensures that when an order status is updated in the store management,
/// the customer orders view is immediately notified of the change.
class OrderSyncService {
  static final OrderSyncService _instance = OrderSyncService._internal();
  factory OrderSyncService() => _instance;
  OrderSyncService._internal();

  final StreamController<OrderUpdateEventBase> _orderUpdateController =
      StreamController<OrderUpdateEventBase>.broadcast();

  /// Stream of order update events
  Stream<OrderUpdateEventBase> get orderUpdates =>
      _orderUpdateController.stream;

  /// Notify that an order has been updated
  void notifyOrderUpdated(
    String orderId,
    String newStatus, {
    String? customerId,
  }) {
    if (!_orderUpdateController.isClosed) {
      final event = SingleOrderUpdateEvent(
        orderId: orderId,
        newStatus: newStatus,
        customerId: customerId,
        timestamp: DateTime.now(),
      );

      _orderUpdateController.add(event);
      debugPrint(
        '📢 Order update notification sent: Order $orderId -> $newStatus',
      );
    }
  }

  /// Notify that multiple orders have been updated
  void notifyBulkOrdersUpdated(List<String> orderIds) {
    if (!_orderUpdateController.isClosed) {
      final event = BulkOrderUpdateEvent(
        orderIds: orderIds,
        timestamp: DateTime.now(),
      );

      _orderUpdateController.add(event);
      debugPrint(
        '📢 Bulk order update notification sent: ${orderIds.length} orders',
      );
    }
  }

  /// Dispose of the service
  void dispose() {
    _orderUpdateController.close();
  }
}

/// Base class for order update events
abstract class OrderUpdateEventBase {
  final DateTime timestamp;

  OrderUpdateEventBase({required this.timestamp});
}

/// Event for when a single order is updated
class SingleOrderUpdateEvent extends OrderUpdateEventBase {
  final String orderId;
  final String newStatus;
  final String? customerId;

  SingleOrderUpdateEvent({
    required this.orderId,
    required this.newStatus,
    this.customerId,
    required DateTime timestamp,
  }) : super(timestamp: timestamp);
}

/// Event for when multiple orders are updated at once
class BulkOrderUpdateEvent extends OrderUpdateEventBase {
  final List<String> orderIds;

  BulkOrderUpdateEvent({required this.orderIds, required DateTime timestamp})
    : super(timestamp: timestamp);
}
