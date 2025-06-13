import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../orders/model/order_model.dart' as order_model;

class DashboardSummary {
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final double totalRevenue;
  final double monthlyRevenue;
  final int totalListings;
  final int activeListings;
  final int soldListings;
  final List<order_model.Order> recentOrders;

  DashboardSummary({
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.totalListings,
    required this.activeListings,
    required this.soldListings,
    required this.recentOrders,
  });
}

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<DashboardSummary> getDashboardSummary() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Get user's store reference
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

    // Get orders data
    final ordersSnapshot =
        await _firestore
            .collection('orders')
            .where('sellerRef', isEqualTo: storeRef)
            .get();

    final orders =
        ordersSnapshot.docs.map((doc) {
          final data = doc.data();
          return order_model.Order(
            id: doc.id,
            buyerRef: data['buyerRef'] as DocumentReference,
            sellerRef: data['sellerRef'] as DocumentReference,
            listingRef: data['listingRef'] as DocumentReference,
            totalAmount: (data['totalAmount'] as num).toDouble(),
            quantity: data['quantity'] as int,
            status: order_model.OrderStatus.values.firstWhere(
              (e) => e.name == data['status'],
              orElse: () => order_model.OrderStatus.pending,
            ),
            shippingAddress: data['shippingAddress'] as String?,
            trackingNumber: data['trackingNumber'] as String?,
            createdAt: data['createdAt'] as Timestamp,
            updatedAt: data['updatedAt'] as Timestamp?,
          );
        }).toList();

    // Get listings data
    final listingsSnapshot =
        await _firestore
            .collection('listings')
            .where('sellerRef', isEqualTo: storeRef)
            .get();

    final listings = listingsSnapshot.docs.length;

    // Calculate metrics
    final totalOrders = orders.length;
    final pendingOrders =
        orders
            .where(
              (o) =>
                  o.status == order_model.OrderStatus.pending ||
                  o.status == order_model.OrderStatus.confirmed,
            )
            .length;
    final completedOrders =
        orders
            .where((o) => o.status == order_model.OrderStatus.delivered)
            .length;

    final totalRevenue = orders
        .where((o) => o.status == order_model.OrderStatus.delivered)
        .fold(0.0, (sum, order) => sum + order.totalAmount);

    // Calculate monthly revenue (current month)
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthlyRevenue = orders
        .where(
          (o) =>
              o.status == order_model.OrderStatus.delivered &&
              o.createdAt.toDate().isAfter(monthStart),
        )
        .fold(0.0, (sum, order) => sum + order.totalAmount);

    // Get recent orders (last 5)
    final recentOrders = orders.take(5).toList();

    // For now, assume all listings are active (you might want to add a status field)
    final activeListings = listings;
    final soldListings =
        orders
            .where((o) => o.status == order_model.OrderStatus.delivered)
            .map((o) => o.listingRef.id)
            .toSet()
            .length;

    return DashboardSummary(
      totalOrders: totalOrders,
      pendingOrders: pendingOrders,
      completedOrders: completedOrders,
      totalRevenue: totalRevenue,
      monthlyRevenue: monthlyRevenue,
      totalListings: listings,
      activeListings: activeListings,
      soldListings: soldListings,
      recentOrders: recentOrders,
    );
  }
}
