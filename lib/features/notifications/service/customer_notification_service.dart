import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/customer_notification_model.dart';

class CustomerNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final CollectionReference<CustomerNotification> _notificationsRef;

  CustomerNotificationService() {
    _notificationsRef = _firestore
        .collection('customer_notifications')
        .withConverter<CustomerNotification>(
          fromFirestore: CustomerNotification.fromFirestore,
          toFirestore:
              (CustomerNotification notification, _) =>
                  notification.toFirestore(),
        );
  }

  /// Get notifications stream for the current user
  Stream<List<CustomerNotification>> getNotificationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _notificationsRef
        .where('customerId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Get unread notifications count for the current user
  Stream<int> getUnreadNotificationsCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _notificationsRef
        .where('customerId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      throw e;
    }
  }

  /// Mark all notifications as read for the current user
  Future<void> markAllAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final batch = _firestore.batch();
      final unreadNotifications =
          await _notificationsRef
              .where('customerId', isEqualTo: currentUser.uid)
              .where('isRead', isEqualTo: false)
              .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      throw e;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
      throw e;
    }
  }

  /// Create order confirmation notification
  Future<void> createOrderConfirmationNotification({
    required String customerId,
    required String orderId,
    required String orderNumber,
    required double totalAmount,
    required String storeName,
  }) async {
    try {
      final notification = CustomerNotification(
        id: '',
        customerId: customerId,
        title: 'Order Confirmed!',
        message:
            'Your order #$orderNumber from $storeName has been confirmed. Total: \$${totalAmount.toStringAsFixed(2)}',
        type: CustomerNotificationType.orderConfirmed,
        isRead: false,
        createdAt: Timestamp.now(),
        metadata: {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'totalAmount': totalAmount,
          'storeName': storeName,
        },
        actionUrl: '/orders/$orderId',
      );

      await _notificationsRef.add(notification);
    } catch (e) {
      print('Error creating order confirmation notification: $e');
    }
  }

  /// Create order shipped notification
  Future<void> createOrderShippedNotification({
    required String customerId,
    required String orderId,
    required String orderNumber,
    required String storeName,
    String? trackingNumber,
  }) async {
    try {
      String message =
          'Your order #$orderNumber from $storeName has been shipped!';
      if (trackingNumber != null) {
        message += ' Tracking: $trackingNumber';
      }

      final notification = CustomerNotification(
        id: '',
        customerId: customerId,
        title: 'Order Shipped!',
        message: message,
        type: CustomerNotificationType.orderShipped,
        isRead: false,
        createdAt: Timestamp.now(),
        metadata: {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'storeName': storeName,
          'trackingNumber': trackingNumber,
        },
        actionUrl: '/orders/$orderId',
      );

      await _notificationsRef.add(notification);
    } catch (e) {
      print('Error creating order shipped notification: $e');
    }
  }

  /// Create order delivered notification
  Future<void> createOrderDeliveredNotification({
    required String customerId,
    required String orderId,
    required String orderNumber,
    required String storeName,
  }) async {
    try {
      final notification = CustomerNotification(
        id: '',
        customerId: customerId,
        title: 'Order Delivered!',
        message:
            'Your order #$orderNumber from $storeName has been delivered. Enjoy your books!',
        type: CustomerNotificationType.orderDelivered,
        isRead: false,
        createdAt: Timestamp.now(),
        metadata: {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'storeName': storeName,
        },
        actionUrl: '/orders/$orderId',
      );

      await _notificationsRef.add(notification);
    } catch (e) {
      print('Error creating order delivered notification: $e');
    }
  }

  /// Create new book available notification
  Future<void> createNewBookNotification({
    required String customerId,
    required String bookTitle,
    required String author,
    required String storeId,
    required String storeName,
    String? bookImageUrl,
  }) async {
    try {
      final notification = CustomerNotification(
        id: '',
        customerId: customerId,
        title: 'New Book Available!',
        message: '"$bookTitle" by $author is now available at $storeName',
        type: CustomerNotificationType.newBookAvailable,
        isRead: false,
        createdAt: Timestamp.now(),
        metadata: {
          'bookTitle': bookTitle,
          'author': author,
          'storeId': storeId,
          'storeName': storeName,
        },
        imageUrl: bookImageUrl,
        actionUrl: '/store/$storeId',
      );

      await _notificationsRef.add(notification);
    } catch (e) {
      print('Error creating new book notification: $e');
    }
  }

  /// Create promotional offer notification
  Future<void> createPromotionalNotification({
    required String customerId,
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final notification = CustomerNotification(
        id: '',
        customerId: customerId,
        title: title,
        message: message,
        type: CustomerNotificationType.promotionalOffer,
        isRead: false,
        createdAt: Timestamp.now(),
        metadata: metadata,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
      );

      await _notificationsRef.add(notification);
    } catch (e) {
      print('Error creating promotional notification: $e');
    }
  }

  /// Create system update notification
  Future<void> createSystemNotification({
    required String customerId,
    required String title,
    required String message,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final notification = CustomerNotification(
        id: '',
        customerId: customerId,
        title: title,
        message: message,
        type: CustomerNotificationType.systemUpdate,
        isRead: false,
        createdAt: Timestamp.now(),
        metadata: metadata,
        actionUrl: actionUrl,
      );

      await _notificationsRef.add(notification);
    } catch (e) {
      print('Error creating system notification: $e');
    }
  }

  /// Create order cancellation notification
  Future<void> createOrderCancellationNotification({
    required String customerId,
    required String orderId,
    required String orderNumber,
    required String storeName,
    String? reason,
  }) async {
    try {
      String message = 'Your order #$orderNumber from $storeName has been cancelled.';
      if (reason != null && reason.isNotEmpty) {
        message += ' Reason: $reason';
      }

      final notification = CustomerNotification(
        id: '',
        customerId: customerId,
        title: 'Order Cancelled',
        message: message,
        type: CustomerNotificationType.orderCancelled,
        isRead: false,
        createdAt: Timestamp.now(),
        metadata: {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'storeName': storeName,
          'reason': reason,
        },
        actionUrl: '/orders/$orderId',
      );

      await _notificationsRef.add(notification);
    } catch (e) {
      print('Error creating order cancellation notification: $e');
    }
  }

  /// Create order rejection notification  
  Future<void> createOrderRejectionNotification({
    required String customerId,
    required String orderId,
    required String orderNumber,
    required String storeName,
    String? reason,
  }) async {
    try {
      String message = 'Your order #$orderNumber from $storeName has been rejected.';
      if (reason != null && reason.isNotEmpty) {
        message += ' Reason: $reason';
      }

      final notification = CustomerNotification(
        id: '',
        customerId: customerId,
        title: 'Order Rejected',
        message: message,
        type: CustomerNotificationType.orderCancelled, // Using orderCancelled type for now
        isRead: false,
        createdAt: Timestamp.now(),
        metadata: {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'storeName': storeName,
          'reason': reason,
          'type': 'rejected',
        },
        actionUrl: '/orders/$orderId',
      );

      await _notificationsRef.add(notification);
    } catch (e) {
      print('Error creating order rejection notification: $e');
    }
  }
}
