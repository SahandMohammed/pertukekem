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
