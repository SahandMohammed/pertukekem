import 'dart:async';
import 'package:flutter/foundation.dart';

class OrderSyncService {
  static final OrderSyncService _instance = OrderSyncService._internal();
  factory OrderSyncService() => _instance;
  OrderSyncService._internal();

  final StreamController<OrderUpdateEventBase> _orderUpdateController =
      StreamController<OrderUpdateEventBase>.broadcast();

  Stream<OrderUpdateEventBase> get orderUpdates =>
      _orderUpdateController.stream;

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

  void dispose() {
    _orderUpdateController.close();
  }
}

abstract class OrderUpdateEventBase {
  final DateTime timestamp;

  OrderUpdateEventBase({required this.timestamp});
}

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

class BulkOrderUpdateEvent extends OrderUpdateEventBase {
  final List<String> orderIds;

  BulkOrderUpdateEvent({required this.orderIds, required DateTime timestamp})
    : super(timestamp: timestamp);
}
