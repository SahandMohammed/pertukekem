import 'package:flutter/material.dart';
import '../model/customer_notification_model.dart';
import '../service/customer_notification_service.dart';

class CustomerNotificationViewModel extends ChangeNotifier {
  final CustomerNotificationService _notificationService =
      CustomerNotificationService();

  List<CustomerNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<CustomerNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasUnreadNotifications => _unreadCount > 0;

  /// Initialize the viewmodel and start listening to notifications
  void initialize() {
    _listenToNotifications();
    _listenToUnreadCount();
  }

  /// Listen to notifications stream
  void _listenToNotifications() {
    _notificationService.getNotificationsStream().listen(
      (notifications) {
        _notifications = notifications;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        print('Error listening to notifications: $error');
        notifyListeners();
      },
    );
  }

  /// Listen to unread count stream
  void _listenToUnreadCount() {
    _notificationService.getUnreadNotificationsCount().listen(
      (count) {
        _unreadCount = count;
        notifyListeners();
      },
      onError: (error) {
        print('Error listening to unread count: $error');
      },
    );
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
    } catch (e) {
      _error = 'Failed to mark notification as read';
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _notificationService.markAllAsRead();
    } catch (e) {
      _error = 'Failed to mark all notifications as read';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
    } catch (e) {
      _error = 'Failed to delete notification';
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get notifications by type
  List<CustomerNotification> getNotificationsByType(
    CustomerNotificationType type,
  ) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get unread notifications
  List<CustomerNotification> get unreadNotifications {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Get read notifications
  List<CustomerNotification> get readNotifications {
    return _notifications.where((n) => n.isRead).toList();
  }

  /// Get today's notifications
  List<CustomerNotification> get todayNotifications {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _notifications.where((n) {
      final notificationDate = n.createdAt.toDate();
      final notificationDay = DateTime(
        notificationDate.year,
        notificationDate.month,
        notificationDate.day,
      );
      return notificationDay.isAtSameMomentAs(today);
    }).toList();
  }

  /// Get this week's notifications
  List<CustomerNotification> get thisWeekNotifications {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    return _notifications.where((n) {
      final notificationDate = n.createdAt.toDate();
      return notificationDate.isAfter(weekStartDay);
    }).toList();
  }

  /// Get order-related notifications
  List<CustomerNotification> get orderNotifications {
    return _notifications
        .where(
          (n) => [
            CustomerNotificationType.orderConfirmed,
            CustomerNotificationType.orderShipped,
            CustomerNotificationType.orderDelivered,
            CustomerNotificationType.orderCancelled,
            CustomerNotificationType.orderRefunded,
          ].contains(n.type),
        )
        .toList();
  }

  /// Get book-related notifications
  List<CustomerNotification> get bookNotifications {
    return _notifications
        .where(
          (n) => [
            CustomerNotificationType.newBookAvailable,
            CustomerNotificationType.libraryUpdate,
          ].contains(n.type),
        )
        .toList();
  }

  /// Get promotional notifications
  List<CustomerNotification> get promotionalNotifications {
    return _notifications
        .where((n) => n.type == CustomerNotificationType.promotionalOffer)
        .toList();
  }
}
