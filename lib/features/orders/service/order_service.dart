import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/order_model.dart' as order_model;

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final CollectionReference<order_model.Order> _ordersRef;

  OrderService() {
    _ordersRef = _firestore
        .collection('orders')
        .withConverter<order_model.Order>(
          fromFirestore: order_model.Order.fromFirestore,
          toFirestore: (order_model.Order order, _) => order.toFirestore(),
        );
  }

  Stream<List<order_model.Order>> getSellerOrders() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // First get the user's store ID
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

          final storeRef = _firestore.collection('stores').doc(storeId);

          return _ordersRef
              .where('sellerRef', isEqualTo: storeRef)
              .orderBy('createdAt', descending: true)
              .snapshots()
              .map(
                (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
              );
        });
  }

  Future<void> updateOrderStatus(
    String orderId,
    order_model.OrderStatus newStatus,
  ) async {
    if (orderId.isEmpty) {
      throw ArgumentError('Order ID cannot be empty');
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final orderDoc = await _ordersRef.doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final order = orderDoc.data()!;
      if (order.sellerRef.id != currentUser.uid) {
        throw Exception('Not authorized to update this order');
      }

      await _ordersRef.doc(orderId).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> updateTrackingNumber(
    String orderId,
    String trackingNumber,
  ) async {
    if (orderId.isEmpty) {
      throw ArgumentError('Order ID cannot be empty');
    }
    if (trackingNumber.isEmpty) {
      throw ArgumentError('Tracking number cannot be empty');
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final orderDoc = await _ordersRef.doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final order = orderDoc.data()!;
      if (order.sellerRef.id != currentUser.uid) {
        throw Exception('Not authorized to update this order');
      }

      await _ordersRef.doc(orderId).update({
        'trackingNumber': trackingNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update tracking number: $e');
    }
  }
}
