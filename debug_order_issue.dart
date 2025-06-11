// Debug script to help identify the order reference mismatch issue
// This is a standalone debug file to analyze the issue

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  // Initialize Firebase (in actual implementation)
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  print('=== ORDER REFERENCE MISMATCH DEBUG ===');

  // Simulate the order creation flow
  print('\n1. CHECKING ORDER CREATION FLOW:');
  print('   - During checkout, sellerRef comes from listing.sellerRef');
  print('   - This should be /stores/{userId} for store owners');

  // Simulate the order querying flow
  print('\n2. CHECKING ORDER QUERYING FLOW:');
  print('   - getSellerOrders() gets user.storeId from user document');
  print('   - Creates storeRef as /stores/{storeId}');
  print('   - Queries orders where sellerRef == storeRef');

  print('\n3. POTENTIAL ISSUE:');
  print('   - If storeId in user document != userId, there will be a mismatch');
  print(
    '   - Current implementation sets storeId = userId in StoreViewModel.createStore()',
  );
  print('   - But maybe there are old orders with different references');

  print('\n4. SOLUTION:');
  print('   - Debug the actual sellerRef values in orders');
  print('   - Debug the storeId in user documents');
  print('   - Ensure consistency between order creation and querying');
}

// Potential debugging functions that could be added to OrderService
class OrderDebugHelper {
  static Future<void> debugOrderReferences() async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    print('=== DEBUGGING ORDER REFERENCES ===');

    // 1. Check user document
    final userDoc =
        await firestore.collection('users').doc(currentUser.uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final storeId = userData['storeId'];
      print('User storeId: $storeId');
      print('User UID: ${currentUser.uid}');
      print('StoreId == UID: ${storeId == currentUser.uid}');
    }

    // 2. Check all orders for this user
    final ordersSnapshot = await firestore.collection('orders').get();
    print('\nAnalyzing all orders:');

    for (final doc in ordersSnapshot.docs) {
      final data = doc.data();
      final sellerRef = data['sellerRef'] as DocumentReference;
      final buyerRef = data['buyerRef'] as DocumentReference;

      print('Order ${doc.id}:');
      print('  - sellerRef: ${sellerRef.path}');
      print('  - buyerRef: ${buyerRef.path}');

      // Check if this order belongs to current user as seller
      if (sellerRef.path == 'stores/${currentUser.uid}' ||
          sellerRef.path == 'users/${currentUser.uid}') {
        print('  - This order belongs to current user as SELLER');
      }

      // Check if this order belongs to current user as buyer
      if (buyerRef.path == 'users/${currentUser.uid}') {
        print('  - This order belongs to current user as BUYER');
      }
    }

    // 3. Check what the current query would return
    final userStoreId = userDoc.data()?['storeId'];
    if (userStoreId != null) {
      final storeRef = firestore.collection('stores').doc(userStoreId);
      final sellerOrdersSnapshot =
          await firestore
              .collection('orders')
              .where('sellerRef', isEqualTo: storeRef)
              .get();

      print('\nCurrent query results (sellerRef == /stores/$userStoreId):');
      print('Found ${sellerOrdersSnapshot.docs.length} orders');
      for (final doc in sellerOrdersSnapshot.docs) {
        print('  - Order: ${doc.id}');
      }
    }
  }

  static Future<void> debugListingReferences() async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    print('\n=== DEBUGGING LISTING REFERENCES ===');

    // Check all listings for this user
    final listingsSnapshot = await firestore.collection('listings').get();

    for (final doc in listingsSnapshot.docs) {
      final data = doc.data();
      final sellerRef = data['sellerRef'] as DocumentReference;
      final sellerType = data['sellerType'] as String;

      if (sellerRef.path == 'stores/${currentUser.uid}' ||
          sellerRef.path == 'users/${currentUser.uid}') {
        print('Listing ${doc.id}:');
        print('  - sellerRef: ${sellerRef.path}');
        print('  - sellerType: $sellerType');
      }
    }
  }
}
