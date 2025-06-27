
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  print('=== ORDER REFERENCE MISMATCH DEBUG ===');

  print('\n1. CHECKING ORDER CREATION FLOW:');
  print('   - During checkout, sellerRef comes from listing.sellerRef');
  print('   - This should be /stores/{userId} for store owners');

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

class OrderDebugHelper {
  static Future<void> debugOrderReferences() async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    print('=== DEBUGGING ORDER REFERENCES ===');

    final userDoc =
        await firestore.collection('users').doc(currentUser.uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final storeId = userData['storeId'];
      print('User storeId: $storeId');
      print('User UID: ${currentUser.uid}');
      print('StoreId == UID: ${storeId == currentUser.uid}');
    }

    final ordersSnapshot = await firestore.collection('orders').get();
    print('\nAnalyzing all orders:');

    for (final doc in ordersSnapshot.docs) {
      final data = doc.data();
      final sellerRef = data['sellerRef'] as DocumentReference;
      final buyerRef = data['buyerRef'] as DocumentReference;

      print('Order ${doc.id}:');
      print('  - sellerRef: ${sellerRef.path}');
      print('  - buyerRef: ${buyerRef.path}');

      if (sellerRef.path == 'stores/${currentUser.uid}' ||
          sellerRef.path == 'users/${currentUser.uid}') {
        print('  - This order belongs to current user as SELLER');
      }

      if (buyerRef.path == 'users/${currentUser.uid}') {
        print('  - This order belongs to current user as BUYER');
      }
    }

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
