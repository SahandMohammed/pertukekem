import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final CollectionReference<StoreNotification> _notificationsRef;

  NotificationService() {
    _notificationsRef = _firestore
        .collection('notifications')
        .withConverter<StoreNotification>(
          fromFirestore: StoreNotification.fromFirestore,
          toFirestore:
              (StoreNotification notification, _) => notification.toFirestore(),
        );
  }

  /// Create notification for new order
  Future<void> createNewOrderNotification({
    required String storeId,
    required String orderId,
    required String orderNumber,
    required double totalAmount,
    required String customerName,
  }) async {
    try {
      final notification = StoreNotification(
        id: '',
        storeId: storeId,
        title: 'New Order Received!',
        message:
            'Order #$orderNumber from $customerName (\$${totalAmount.toStringAsFixed(2)})',
        type: NotificationType.newOrder,
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

      // Also create a push notification trigger document
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

  /// Create notification for order status update
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

      final notification = StoreNotification(
        id: '',
        storeId: storeId,
        title: title,
        message: message,
        type: NotificationType.orderUpdate,
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

      // Create push notification trigger
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

  /// Create notification for order cancellation
  Future<void> createOrderCancellationNotification({
    required String storeId,
    required String orderId,
    required String orderNumber,
    required String customerName,
    required double refundAmount,
  }) async {
    try {
      final notification = StoreNotification(
        id: '',
        storeId: storeId,
        title: 'Order Cancelled',
        message:
            'Order #$orderNumber from $customerName has been cancelled. Refund: \$${refundAmount.toStringAsFixed(2)}',
        type: NotificationType.orderCancelled,
        isRead: false,
        createdAt: Timestamp.now(),
        metadata: {
          'orderId': orderId,
          'orderNumber': orderNumber,
          'customerName': customerName,
          'refundAmount': refundAmount,
        },
      );

      await _notificationsRef.add(notification);

      // Create push notification trigger
      await _createPushNotificationTrigger(
        storeId: storeId,
        type: 'order_cancelled',
        title: notification.title,
        body: notification.message,
        data: {
          'type': 'order_cancelled',
          'orderId': orderId,
          'orderNumber': orderNumber,
        },
      );
    } catch (e) {
      print('Error creating order cancellation notification: $e');
    }
  }

  /// Create push notification trigger document for Cloud Functions
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

  Stream<List<StoreNotification>> getStoreNotifications({int limit = 10}) {
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
              .where('storeId', isEqualTo: storeId)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .snapshots()
              .map(
                (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
              );
        });
  }

  Future<int> getUnreadCount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw 0;
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
              .where('storeId', isEqualTo: storeId)
              .where('isRead', isEqualTo: false)
              .count()
              .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();

    if (!userDoc.exists) return;

    final storeId = userDoc.data()?['storeId'];
    if (storeId == null || storeId.isEmpty) return;

    final batch = _firestore.batch();
    final unreadNotifications =
        await _notificationsRef
            .where('storeId', isEqualTo: storeId)
            .where('isRead', isEqualTo: false)
            .get();

    for (final doc in unreadNotifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}
