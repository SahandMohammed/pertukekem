import 'package:flutter/material.dart';
import 'dart:async';
import '../model/unified_notification_model.dart';
import '../service/unified_notification_service.dart';

class CustomerNotificationViewModel extends ChangeNotifier {
  final UnifiedNotificationService _notificationService =
      UnifiedNotificationService();
  List<UnifiedNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  StreamSubscription<List<UnifiedNotification>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;

  List<UnifiedNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasUnreadNotifications => _unreadCount > 0;

  Future<void> initialize() async {
    if (_isInitialized) {
      return; // Prevent multiple initializations
    }

    _isInitialized = true;

    await _notificationsSubscription?.cancel();
    await _unreadCountSubscription?.cancel();

    _listenToNotifications();
    _listenToUnreadCount();
  }

  void _listenToNotifications() {
    print('🔔 Starting to listen to customer notifications');
    _notificationsSubscription = _notificationService
        .getCustomerNotificationsStream()
        .listen(
          (notifications) {
            print('🔔 Received ${notifications.length} notifications');
            _notifications = notifications;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            print('❌ Error listening to notifications: $error');
            notifyListeners();
          },
        );
  }

  void _listenToUnreadCount() {
    print('🔔 Starting to listen to unread count');
    _unreadCountSubscription = _notificationService
        .getCustomerUnreadNotificationsCount()
        .listen(
          (count) {
            print('🔔 Unread count updated: $count');
            _unreadCount = count;
            notifyListeners();
          },
          onError: (error) {
            print('❌ Error listening to unread count: $error');
          },
        );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
    } catch (e) {
      _error = 'Failed to mark notification as read';
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _notificationService.markAllAsRead(
        target: NotificationTarget.customer,
      );
    } catch (e) {
      _error = 'Failed to mark all notifications as read';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
    } catch (e) {
      _error = 'Failed to delete notification';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<UnifiedNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  List<UnifiedNotification> get unreadNotifications {
    return _notifications.where((n) => !n.isRead).toList();
  }

  List<UnifiedNotification> get readNotifications {
    return _notifications.where((n) => n.isRead).toList();
  }

  List<UnifiedNotification> get todayNotifications {
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

  List<UnifiedNotification> get thisWeekNotifications {
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

  List<UnifiedNotification> get orderNotifications {
    return _notifications
        .where(
          (n) => [
            NotificationType.orderConfirmed,
            NotificationType.orderShipped,
            NotificationType.orderDelivered,
            NotificationType.orderCancelled,
            NotificationType.orderRefunded,
          ].contains(n.type),
        )
        .toList();
  }

  List<UnifiedNotification> get bookNotifications {
    return _notifications
        .where(
          (n) => [
            NotificationType.newBookAvailable,
            NotificationType.libraryUpdate,
          ].contains(n.type),
        )
        .toList();
  }

  List<UnifiedNotification> get promotionalNotifications {
    return _notifications
        .where((n) => n.type == NotificationType.promotionalOffer)
        .toList();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    super.dispose();
  }
}
