import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../model/order_model.dart' as order_model;
import '../../dashboards/store/service/notification_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
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
      final orderId =
          docRef.id; // Create notification for store owner about new order
      try {
        // Get buyer information for notification
        final buyerDoc = await buyerRef.get();
        String customerName = 'Customer';
        if (buyerDoc.exists) {
          final data = buyerDoc.data();
          if (data is Map<String, dynamic> && data.containsKey('fullName')) {
            customerName = data['fullName'] ?? 'Customer';
          }
        }

        // Determine storeId based on seller type
        String storeId;
        if (sellerRef.path.startsWith('stores/')) {
          // Seller is a store, use the store ID directly
          storeId = sellerRef.id;
        } else if (sellerRef.path.startsWith('users/')) {
          // Seller is a user, get their storeId from user document
          final sellerDoc = await sellerRef.get();
          if (sellerDoc.exists) {
            final sellerData = sellerDoc.data();
            if (sellerData is Map<String, dynamic> &&
                sellerData.containsKey('storeId')) {
              storeId = sellerData['storeId'];
            } else {
              // User doesn't have a store, skip notification
              print(
                'User seller ${sellerRef.id} does not have a store, skipping notification',
              );
              return orderId;
            }
          } else {
            print('Seller document not found: ${sellerRef.path}');
            return orderId;
          }
        } else {
          print('Unknown seller reference format: ${sellerRef.path}');
          return orderId;
        }

        await _notificationService.createNewOrderNotification(
          storeId: storeId,
          orderId: orderId,
          orderNumber: orderId.substring(0, 8).toUpperCase(),
          totalAmount: totalAmount,
          customerName: customerName,
        );
      } catch (e) {
        // Don't fail order creation if notification fails
        print('Failed to create order notification: $e');
      }

      return orderId;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Stream<List<order_model.Order>> getSellerOrders() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.error(Exception('User not authenticated'));
    }

    // Create a stream controller to manage the orders stream
    late StreamController<List<order_model.Order>> controller;
    StreamSubscription<QuerySnapshot<order_model.Order>>? ordersSubscription;
    controller = StreamController<List<order_model.Order>>.broadcast(
      onListen: () async {
        try {
          debugPrint('🔍 Getting store ID for orders stream...');

          // Get store ID directly without stream chaining
          final userDoc =
              await _firestore.collection('users').doc(currentUser.uid).get();

          if (!userDoc.exists) {
            controller.addError(Exception('User document not found'));
            return;
          }

          final storeId = userDoc.data()?['storeId'];
          if (storeId == null || storeId.isEmpty) {
            controller.addError(Exception('Store ID not found'));
            return;
          }

          debugPrint('✅ Store ID found: $storeId');

          final storeRef = _firestore.collection('stores').doc(storeId);

          // Subscribe to orders stream
          ordersSubscription = _ordersRef
              .where('sellerRef', isEqualTo: storeRef)
              .orderBy('createdAt', descending: true)
              .snapshots(includeMetadataChanges: false)
              .listen(
                (snapshot) {
                  final orders =
                      snapshot.docs.map((doc) => doc.data()).toList();
                  debugPrint('📦 Loaded ${orders.length} orders from stream');
                  controller.add(orders);
                },
                onError: (error) {
                  debugPrint('❌ Orders stream error: $error');
                  controller.addError(error);
                },
              );
        } catch (e) {
          debugPrint('❌ Error setting up orders stream: $e');
          controller.addError(e);
        }
      },
      onCancel: () {
        debugPrint('🔄 Cancelling orders stream subscription');
        ordersSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  // Check if store exists
  Future<bool> checkStoreExists() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      debugPrint('🔍 Checking if store exists for user: ${currentUser.uid}');

      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        debugPrint('❌ User document not found');
        return false;
      }

      final storeId = userDoc.data()?['storeId'];
      if (storeId == null || storeId.isEmpty) {
        debugPrint('❌ Store ID not found in user document');
        return false;
      }

      debugPrint('✅ Store ID found: $storeId');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking store existence: $e');
      return false;
    }
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
        .snapshots(includeMetadataChanges: false) // Reduce cache dependence
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Force refresh orders from server (no cache)
  Future<List<order_model.Order>> getBuyerOrdersFromServer() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    print('🔍 Fetching orders from server for user: ${currentUser.uid}');
    final buyerRef = _firestore.collection('users').doc(currentUser.uid);
    final snapshot = await _ordersRef
        .where('buyerRef', isEqualTo: buyerRef)
        .orderBy('createdAt', descending: true)
        .get(GetOptions(source: Source.server)); // Force server data

    final orders = snapshot.docs.map((doc) => doc.data()).toList();
    print('🎯 Server returned ${orders.length} orders');
    print(
      '📊 Snapshot metadata - from cache: ${snapshot.metadata.isFromCache}',
    );

    return orders;
  }

  // Get delivered orders for a buyer (for library purposes)
  Future<List<order_model.Order>> getDeliveredOrdersForBuyer(
    String buyerId,
  ) async {
    final buyerRef = _firestore.collection('users').doc(buyerId);

    final snapshot =
        await _ordersRef
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
      }); // Create notification for order status update
      try {
        // Get buyer information for notification
        final buyerDoc = await order.buyerRef.get();
        String customerName = 'Customer';
        if (buyerDoc.exists) {
          final data = buyerDoc.data();
          if (data is Map<String, dynamic> && data.containsKey('fullName')) {
            customerName = data['fullName'] ?? 'Customer';
          }
        }

        // Determine storeId based on seller type
        String storeId;
        if (order.sellerRef.path.startsWith('stores/')) {
          // Seller is a store, use the store ID directly
          storeId = order.sellerRef.id;
        } else if (order.sellerRef.path.startsWith('users/')) {
          // Seller is a user, get their storeId from user document
          final sellerDoc = await order.sellerRef.get();
          if (sellerDoc.exists) {
            final sellerData = sellerDoc.data();
            if (sellerData is Map<String, dynamic> &&
                sellerData.containsKey('storeId')) {
              storeId = sellerData['storeId'];
            } else {
              // User doesn't have a store, skip notification
              print(
                'User seller ${order.sellerRef.id} does not have a store, skipping notification',
              );
              return;
            }
          } else {
            print('Seller document not found: ${order.sellerRef.path}');
            return;
          }
        } else {
          print('Unknown seller reference format: ${order.sellerRef.path}');
          return;
        }

        await _notificationService.createOrderUpdateNotification(
          storeId: storeId,
          orderId: orderId,
          orderNumber: orderId.substring(0, 8).toUpperCase(),
          newStatus: newStatus.name,
          customerName: customerName,
        );
      } catch (e) {
        // Don't fail order update if notification fails
        print('Failed to create order update notification: $e');
      }
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

  // Force refresh seller orders from server (no cache)
  Future<List<order_model.Order>> getSellerOrdersFromServer() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Get the user's store ID
    final userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();

    if (!userDoc.exists) {
      throw Exception('User document not found');
    }

    final storeId = userDoc.data()?['storeId'];

    if (storeId == null || storeId.isEmpty) {
      throw Exception('Store ID not found');
    }

    final storeRef = _firestore.collection('stores').doc(storeId);
    final snapshot = await _ordersRef
        .where('sellerRef', isEqualTo: storeRef)
        .orderBy('createdAt', descending: true)
        .get(GetOptions(source: Source.server)); // Force server data

    return snapshot.docs.map((doc) => doc.data()).toList();
  } // Check if orders collection exists and has data

  Future<void> checkOrdersCollectionStatus() async {
    try {
      print('🔍 Checking orders collection status...');

      // Check if collection exists by trying to get any document
      final snapshot = await _firestore
          .collection('orders')
          .limit(1)
          .get(GetOptions(source: Source.server));

      print('📊 Orders collection exists: ${snapshot.docs.isNotEmpty}');
      print('📦 Total docs in first check: ${snapshot.docs.length}');

      // Check total count
      final countSnapshot = await _firestore.collection('orders').count().get();

      print('🔢 Total orders in collection: ${countSnapshot.count}');

      // Check if current user has any orders
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final buyerRef = _firestore.collection('users').doc(currentUser.uid);
        final userOrdersSnapshot =
            await _firestore
                .collection('orders')
                .where('buyerRef', isEqualTo: buyerRef)
                .count()
                .get();

        print('👤 Orders for current user: ${userOrdersSnapshot.count}');
      }
    } catch (e) {
      print('❌ Error checking orders collection: $e');
    }
  }

  // Debug methods to help identify order reference issues
  Future<void> debugOrderReferences() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ No authenticated user for debugging');
      return;
    }

    print('=== DEBUGGING ORDER REFERENCES ===');
    print('🔍 Current user UID: ${currentUser.uid}');

    try {
      // 1. Check user document and storeId
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final storeId = userData['storeId'];
        print('📄 User document storeId: $storeId');
        print('✅ StoreId matches UID: ${storeId == currentUser.uid}');

        // 2. Check if store document exists
        if (storeId != null) {
          final storeDoc =
              await _firestore.collection('stores').doc(storeId).get();
          print('🏪 Store document exists: ${storeDoc.exists}');
          if (storeDoc.exists) {
            final storeData = storeDoc.data()!;
            print('🏪 Store name: ${storeData['storeName']}');
            print('🏪 Store ownerId: ${storeData['ownerId']}');
          }
        }
      } else {
        print('❌ User document not found');
        return;
      }

      // 3. Check all orders in the system
      final ordersSnapshot = await _firestore.collection('orders').get();
      print('\n📦 Total orders in system: ${ordersSnapshot.docs.length}');

      int userAsSellerCount = 0;
      int userAsBuyerCount = 0;
      List<String> userSellerOrders = [];
      List<String> userBuyerOrders = [];

      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        final sellerRef = data['sellerRef'] as DocumentReference;
        final buyerRef = data['buyerRef'] as DocumentReference;

        // Check if this order belongs to current user as seller
        if (sellerRef.path == 'stores/${currentUser.uid}' ||
            sellerRef.path == 'users/${currentUser.uid}') {
          userAsSellerCount++;
          userSellerOrders.add(doc.id);
          print('📦 Order ${doc.id} - User is SELLER (${sellerRef.path})');
        }

        // Check if this order belongs to current user as buyer
        if (buyerRef.path == 'users/${currentUser.uid}') {
          userAsBuyerCount++;
          userBuyerOrders.add(doc.id);
          print('🛒 Order ${doc.id} - User is BUYER');
        }
      }

      print('\n📊 SUMMARY:');
      print('   - Orders where user is seller: $userAsSellerCount');
      print('   - Orders where user is buyer: $userAsBuyerCount');

      // 4. Test the current getSellerOrders query
      final userStoreId = userDoc.data()?['storeId'];
      if (userStoreId != null) {
        final storeRef = _firestore.collection('stores').doc(userStoreId);
        final sellerOrdersSnapshot =
            await _ordersRef.where('sellerRef', isEqualTo: storeRef).get();

        print('\n🔍 Current getSellerOrders() query results:');
        print('   - Query: sellerRef == /stores/$userStoreId');
        print('   - Found: ${sellerOrdersSnapshot.docs.length} orders');

        if (sellerOrdersSnapshot.docs.isNotEmpty) {
          for (final doc in sellerOrdersSnapshot.docs) {
            final order = doc.data();
            print('   - Order: ${doc.id} (${order.status.name})');
          }
        } else {
          print('   ❌ No orders found with current query!');

          // Check for potential mismatches
          print('\n🔍 Checking for potential reference mismatches:');

          for (final orderId in userSellerOrders) {
            final orderDoc = await _ordersRef.doc(orderId).get();
            if (orderDoc.exists) {
              final order = orderDoc.data()!;
              print('   - Order $orderId sellerRef: ${order.sellerRef.path}');
              print('     Expected: /stores/$userStoreId');
              print(
                '     Match: ${order.sellerRef.path == 'stores/$userStoreId'}',
              );
            }
          }
        }
      }

      // 5. Check listing references for context
      await _debugListingReferences();
    } catch (e) {
      print('❌ Error during debugging: $e');
    }

    print('\n=== END DEBUG ===');
  }

  Future<void> _debugListingReferences() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    print('\n=== DEBUGGING LISTING REFERENCES ===');

    try {
      // Check listings where user is seller
      final listingsSnapshot = await _firestore.collection('listings').get();

      int userListingsCount = 0;

      for (final doc in listingsSnapshot.docs) {
        final data = doc.data();
        final sellerRef = data['sellerRef'] as DocumentReference;
        final sellerType = data['sellerType'] as String;

        if (sellerRef.path == 'stores/${currentUser.uid}' ||
            sellerRef.path == 'users/${currentUser.uid}') {
          userListingsCount++;
          print('📚 Listing ${doc.id}:');
          print('   - sellerRef: ${sellerRef.path}');
          print('   - sellerType: $sellerType');
          print('   - title: ${data['title']}');
        }
      }

      print('📊 Total user listings: $userListingsCount');
    } catch (e) {
      print('❌ Error debugging listings: $e');
    }
  }

  // Debug method to check orders collection status

  // Fix order reference consistency issues
  Future<void> fixOrderReferences() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    print('🔧 Starting order reference fix...');

    try {
      // 1. Get user's store ID
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final storeId = userDoc.data()?['storeId'];
      if (storeId == null || storeId.isEmpty) {
        throw Exception('Store ID not found');
      }

      print('👤 User ID: ${currentUser.uid}');
      print('🏪 Store ID: $storeId');

      // 2. Check if storeId matches userId (it should)
      if (storeId != currentUser.uid) {
        print('⚠️ WARNING: storeId ($storeId) != userId (${currentUser.uid})');
        // This is the root cause - let's fix it
        await _firestore.collection('users').doc(currentUser.uid).update({
          'storeId': currentUser.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Fixed user document storeId');
      }

      // 3. Check all orders where user might be seller
      final allOrdersSnapshot = await _firestore.collection('orders').get();
      List<String> ordersToFix = [];

      for (final doc in allOrdersSnapshot.docs) {
        final data = doc.data();
        final sellerRef = data['sellerRef'] as DocumentReference;

        // Check if this order has old reference that needs fixing
        if (sellerRef.path == 'users/${currentUser.uid}' ||
            sellerRef.path == 'stores/$storeId' ||
            sellerRef.path == 'stores/${currentUser.uid}') {
          ordersToFix.add(doc.id);
        }
      }

      print('📦 Found ${ordersToFix.length} orders that might need fixing');

      // 4. Update orders to use consistent store reference
      final correctStoreRef = _firestore
          .collection('stores')
          .doc(currentUser.uid);

      for (final orderId in ordersToFix) {
        await _firestore.collection('orders').doc(orderId).update({
          'sellerRef': correctStoreRef,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Fixed order $orderId seller reference');
      }

      print('🎉 Order reference fix completed!');
    } catch (e) {
      print('❌ Error fixing order references: $e');
      throw e;
    }
  }
}
