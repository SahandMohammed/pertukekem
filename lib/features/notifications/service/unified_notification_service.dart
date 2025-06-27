import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/unified_notification_model.dart';

class UnifiedNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final CollectionReference<UnifiedNotification> _notificationsRef;

  UnifiedNotificationService() {
    _notificationsRef = _firestore
        .collection('notifications')
        .withConverter<UnifiedNotification>(
          fromFirestore: UnifiedNotification.fromFirestore,
          toFirestore:
              (UnifiedNotification notification, _) =>
                  notification.toFirestore(),
        );
  }


  Stream<List<UnifiedNotification>> getCustomerNotificationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _notificationsRef
        .where('target', isEqualTo: NotificationTarget.customer.name)
        .where('customerId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<int> getCustomerUnreadNotificationsCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _notificationsRef
        .where('target', isEqualTo: NotificationTarget.customer.name)
        .where('customerId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> createOrderConfirmationNotification({
    required String customerId,
    required String orderId,
    required String orderNumber,
    required double totalAmount,
    required String storeName,
  }) async {
    try {
      final notification = UnifiedNotification(
        id: '',
        customerId: customerId,
        title: 'Order Confirmed!',
        message:
            'Your order #$orderNumber from $storeName has been confirmed. Total: \$${totalAmount.toStringAsFixed(2)}',
        type: NotificationType.orderConfirmed,
        target: NotificationTarget.customer,
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

      final notification = UnifiedNotification(
        id: '',
        customerId: customerId,
        title: 'Order Shipped!',
        message: message,
        type: NotificationType.orderShipped,
        target: NotificationTarget.customer,
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

  Future<void> createOrderDeliveredNotification({
    required String customerId,
    required String orderId,
    required String orderNumber,
    required String storeName,
  }) async {
    try {
      final notification = UnifiedNotification(
        id: '',
        customerId: customerId,
        title: 'Order Delivered!',
        message:
            'Your order #$orderNumber from $storeName has been delivered. Enjoy your books!',
        type: NotificationType.orderDelivered,
        target: NotificationTarget.customer,
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

  Future<void> createOrderCancellationNotification({
    required String customerId,
    required String orderId,
    required String orderNumber,
    required String storeName,
    String? reason,
  }) async {
    try {
      String message =
          'Your order #$orderNumber from $storeName has been cancelled.';
      if (reason != null && reason.isNotEmpty) {
        message += ' Reason: $reason';
      }

      final notification = UnifiedNotification(
        id: '',
        customerId: customerId,
        title: 'Order Cancelled',
        message: message,
        type: NotificationType.orderCancelled,
        target: NotificationTarget.customer,
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

  Future<void> createCustomerSystemNotification({
    required String customerId,
    required String title,
    required String message,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final notification = UnifiedNotification(
        id: '',
        customerId: customerId,
        title: title,
        message: message,
        type: NotificationType.systemUpdate,
        target: NotificationTarget.customer,
        isRead: false,
        createdAt: Timestamp.now(),
        metadata: metadata,
        actionUrl: actionUrl,
      );

      await _notificationsRef.add(notification);
    } catch (e) {
      print('Error creating customer system notification: $e');
    }
  }


  Stream<List<UnifiedNotification>> getStoreNotifications({int limit = 10}) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .asyncExpand((userDoc) {
          if (!userDoc.exists) {
            throw Exception('User document not found');
          }

          final storeId = userDoc.data()?['storeId'];
          if (storeId == null || storeId.isEmpty) {
            throw Exception('Store ID not found');
          }

          return _notificationsRef
              .where('target', isEqualTo: NotificationTarget.store.name)
              .where('storeId', isEqualTo: storeId)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .snapshots()
              .map(
                (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
              );
        });
  }

  Future<void> createNewOrderNotification({
    required String storeId,
    required String orderId,
    required String orderNumber,
    required double totalAmount,
    required String customerName,
  }) async {
    try {
      final notification = UnifiedNotification(
        id: '',
        storeId: storeId,
        title: 'New Order Received!',
        message:
            'Order #$orderNumber from $customerName (\$${totalAmount.toStringAsFixed(2)})',
        type: NotificationType.newOrder,
        target: NotificationTarget.store,
        isRead: false,
        createdAt: Timestamp.now(),
        metadata: {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'totalAmount': totalAmount,
          'customerName': customerName,
        },
      );

      await _notificationsRef.add(notification);

      await _createPushNotificationTrigger(
        storeId: storeId,
        type: 'new_order',
        title: notification.title,
        body: notification.message,
        data: {
          'type': 'new_order',
          'orderId': orderId,
          'orderNumber': orderNumber,
        },
      );
    } catch (e) {
      print('Error creating new order notification: $e');
    }
  }

  Future<void> createOrderUpdateNotification({
    required String storeId,
    required String orderId,
    required String orderNumber,
    required String newStatus,
    required String customerName,
  }) async {
    try {
      String title = 'Order Update';
      String message = 'Order #$orderNumber status changed to $newStatus';

      final notification = UnifiedNotification(
        id: '',
        storeId: storeId,
        title: title,
        message: message,
        type: NotificationType.orderUpdate,
        target: NotificationTarget.store,
        isRead: false,
        createdAt: Timestamp.now(),
        metadata: {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'newStatus': newStatus,
          'customerName': customerName,
        },
      );

      await _notificationsRef.add(notification);

      await _createPushNotificationTrigger(
        storeId: storeId,
        type: 'order_update',
        title: title,
        body: message,
        data: {
          'type': 'order_update',
          'orderId': orderId,
          'orderNumber': orderNumber,
          'newStatus': newStatus,
        },
      );
    } catch (e) {
      print('Error creating order update notification: $e');
    }
  }

  Future<void> _createPushNotificationTrigger({
    required String storeId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('pushNotificationTriggers').add({
        'storeId': storeId,
        'type': type,
        'title': title,
        'body': body,
        'data': data ?? {},
        'processed': false,
        'createdAt': FieldValue.serverTimestamp(),
        'retryCount': 0,
      });
    } catch (e) {
      print('Error creating push notification trigger: $e');
    }
  }

  Future<int> getStoreUnreadCount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return 0;
    }

    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        return 0;
      }

      final storeId = userDoc.data()?['storeId'];
      if (storeId == null || storeId.isEmpty) {
        return 0;
      }

      final snapshot =
          await _notificationsRef
              .where('target', isEqualTo: NotificationTarget.store.name)
              .where('storeId', isEqualTo: storeId)
              .where('isRead', isEqualTo: false)
              .count()
              .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Stream<int> getStoreUnreadCountStream() async* {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('⚠️ No current user for store unread count stream');
      yield 0;
      return;
    }

    print('🔍 Starting store unread count stream for user: ${currentUser.uid}');

    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        print('⚠️ User document does not exist');
        yield 0;
        return;
      }

      final storeId = userDoc.data()?['storeId'];
      if (storeId == null || storeId.isEmpty) {
        print('⚠️ No storeId found for user');
        yield 0;
        return;
      }

      print('📍 Setting up real-time stream for store: $storeId');

      await for (final snapshot
          in _notificationsRef
              .where('target', isEqualTo: NotificationTarget.store.name)
              .where('storeId', isEqualTo: storeId)
              .where('isRead', isEqualTo: false)
              .snapshots()) {
        final count = snapshot.docs.length;
        print(
          '📱 Store unread count stream update: $count unread notifications',
        );
        yield count;
      }
    } catch (error) {
      print('❌ Error in store unread count stream: $error');
      yield 0;
    }
  }


  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead({required NotificationTarget target}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final batch = _firestore.batch();
      Query<UnifiedNotification> query;

      if (target == NotificationTarget.customer) {
        query = _notificationsRef
            .where('target', isEqualTo: NotificationTarget.customer.name)
            .where('customerId', isEqualTo: currentUser.uid)
            .where('isRead', isEqualTo: false);
      } else {
        final userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        if (!userDoc.exists) return;

        final storeId = userDoc.data()?['storeId'];
        if (storeId == null || storeId.isEmpty) return;

        query = _notificationsRef
            .where('target', isEqualTo: NotificationTarget.store.name)
            .where('storeId', isEqualTo: storeId)
            .where('isRead', isEqualTo: false);
      }

      final unreadNotifications = await query.get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }
}
