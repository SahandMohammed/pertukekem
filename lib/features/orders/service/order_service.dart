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

  // Create a new order
  Future<String> createOrder({
    required String buyerId,
    required DocumentReference sellerRef,
    required DocumentReference listingRef,
    required double totalAmount,
    int quantity = 1,
    String? shippingAddress,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final buyerRef = _firestore.collection('users').doc(buyerId);
      final now = Timestamp.now();

      final order = order_model.Order(
        id: '', // Will be set by Firestore
        buyerRef: buyerRef,
        sellerRef: sellerRef,
        listingRef: listingRef,
        totalAmount: totalAmount,
        quantity: quantity,
        status: order_model.OrderStatus.pending,
        shippingAddress: shippingAddress,
        trackingNumber: null,
        createdAt: now,
        updatedAt: null,
      );

      final docRef = await _ordersRef.add(order);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
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

  // Get orders for a buyer (customer)
  Stream<List<order_model.Order>> getBuyerOrders() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final buyerRef = _firestore.collection('users').doc(currentUser.uid);

    return _ordersRef
        .where('buyerRef', isEqualTo: buyerRef)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  // Get delivered orders for a buyer (for library purposes)
  Future<List<order_model.Order>> getDeliveredOrdersForBuyer(String buyerId) async {
    final buyerRef = _firestore.collection('users').doc(buyerId);

    final snapshot = await _ordersRef
        .where('buyerRef', isEqualTo: buyerRef)
        .where('status', isEqualTo: order_model.OrderStatus.delivered.name)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
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
