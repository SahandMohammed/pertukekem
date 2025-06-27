import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/admin_user_model.dart';
import '../model/admin_store_model.dart';
import '../model/admin_listing_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<List<AdminUserModel>> getAllCustomers({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map(
            (doc) => AdminUserModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .where((user) => user.isCustomer) // Only include customers
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  Future<List<AdminUserModel>> getAllUsers({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map(
            (doc) => AdminUserModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  Future<void> toggleUserBlock(String userId, bool isBlocked) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBlocked': isBlocked,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  Future<List<AdminUserModel>> searchUsers(String searchTerm) async {
    try {
      final nameQuery =
          await _firestore
              .collection('users')
              .where('firstName', isGreaterThanOrEqualTo: searchTerm)
              .where('firstName', isLessThan: searchTerm + '\uf8ff')
              .limit(10)
              .get();

      final emailQuery =
          await _firestore
              .collection('users')
              .where(
                'email_lowercase',
                isGreaterThanOrEqualTo: searchTerm.toLowerCase(),
              )
              .where(
                'email_lowercase',
                isLessThan: searchTerm.toLowerCase() + '\uf8ff',
              )
              .limit(10)
              .get();

      final Set<String> userIds = {};
      final List<AdminUserModel> users = [];

      for (final doc in [...nameQuery.docs, ...emailQuery.docs]) {
        if (!userIds.contains(doc.id)) {
          userIds.add(doc.id);
          users.add(AdminUserModel.fromMap(doc.data()));
        }
      }

      return users;
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  Future<List<AdminUserModel>> searchCustomers(String searchTerm) async {
    try {
      final nameQuery =
          await _firestore
              .collection('users')
              .where('firstName', isGreaterThanOrEqualTo: searchTerm)
              .where('firstName', isLessThan: searchTerm + '\uf8ff')
              .limit(10)
              .get();

      final emailQuery =
          await _firestore
              .collection('users')
              .where(
                'email_lowercase',
                isGreaterThanOrEqualTo: searchTerm.toLowerCase(),
              )
              .where(
                'email_lowercase',
                isLessThan: searchTerm.toLowerCase() + '\uf8ff',
              )
              .limit(10)
              .get();

      final Set<String> userIds = {};
      final List<AdminUserModel> customers =
          []; // Combine results and remove duplicates, only include customers
      for (final doc in [...nameQuery.docs, ...emailQuery.docs]) {
        if (!userIds.contains(doc.id)) {
          userIds.add(doc.id);
          final user = AdminUserModel.fromMap(doc.data());
          if (user.isCustomer) {
            customers.add(user);
          }
        }
      }

      return customers;
    } catch (e) {
      throw Exception('Failed to search customers: $e');
    }
  }

  Future<List<AdminStoreModel>> getAllStores({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('stores')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      final stores = <AdminStoreModel>[];

      for (final doc in querySnapshot.docs) {
        final storeData = doc.data() as Map<String, dynamic>;

        final ownerDoc =
            await _firestore
                .collection('users')
                .doc(storeData['ownerId'])
                .get();

        if (ownerDoc.exists) {
          final ownerData = ownerDoc.data()!;

          final listingsCount =
              await _firestore
                  .collection('listings')
                  .where('sellerRef', isEqualTo: doc.reference)
                  .count()
                  .get();

          final store = AdminStoreModel.fromMap({
            ...storeData,
            'ownerName': '${ownerData['firstName']} ${ownerData['lastName']}',
            'ownerEmail': ownerData['email'],
            'isBlocked': ownerData['isBlocked'] ?? false,
            'totalListings': listingsCount.count,
          });

          stores.add(store);
        }
      }

      return stores;
    } catch (e) {
      throw Exception('Failed to fetch stores: $e');
    }
  }

  Future<void> toggleStoreBlock(
    String storeId,
    String ownerId,
    bool isBlocked,
  ) async {
    try {
      final batch = _firestore.batch();

      batch.update(_firestore.collection('users').doc(ownerId), {
        'isBlocked': isBlocked,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (isBlocked) {
        final storeRef = _firestore.collection('stores').doc(storeId);
        final listingsQuery =
            await _firestore
                .collection('listings')
                .where('sellerRef', isEqualTo: storeRef)
                .where('status', isEqualTo: 'active')
                .get();

        for (final doc in listingsQuery.docs) {
          batch.update(doc.reference, {
            'status': 'inactive',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update store status: $e');
    }
  }

  Future<List<AdminStoreModel>> searchStores(String searchTerm) async {
    try {
      final query =
          await _firestore
              .collection('stores')
              .where('storeName', isGreaterThanOrEqualTo: searchTerm)
              .where('storeName', isLessThan: searchTerm + '\uf8ff')
              .limit(10)
              .get();

      final stores = <AdminStoreModel>[];

      for (final doc in query.docs) {
        final storeData = doc.data();

        final ownerDoc =
            await _firestore
                .collection('users')
                .doc(storeData['ownerId'])
                .get();

        if (ownerDoc.exists) {
          final ownerData = ownerDoc.data()!;

          final listingsCount =
              await _firestore
                  .collection('listings')
                  .where('sellerRef', isEqualTo: doc.reference)
                  .count()
                  .get();

          final store = AdminStoreModel.fromMap({
            ...storeData,
            'ownerName': '${ownerData['firstName']} ${ownerData['lastName']}',
            'ownerEmail': ownerData['email'],
            'isBlocked': ownerData['isBlocked'] ?? false,
            'totalListings': listingsCount.count,
          });

          stores.add(store);
        }
      }

      return stores;
    } catch (e) {
      throw Exception('Failed to search stores: $e');
    }
  }

  Future<List<AdminListingModel>> getAllListings({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('listings')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      final listings = <AdminListingModel>[];

      for (final doc in querySnapshot.docs) {
        final listingData = doc.data() as Map<String, dynamic>;

        String sellerName = 'Unknown';
        String sellerId = '';

        final sellerRef = listingData['sellerRef'] as DocumentReference?;
        if (sellerRef != null) {
          try {
            final sellerDoc = await sellerRef.get();
            if (sellerDoc.exists) {
              final sellerData = sellerDoc.data() as Map<String, dynamic>;

              if (listingData['sellerType'] == 'store') {
                sellerName = sellerData['storeName'] ?? 'Unknown Store';
                sellerId = sellerData['storeId'] ?? '';
              } else {
                final userDoc =
                    await _firestore
                        .collection('users')
                        .doc(sellerData['ownerId'] ?? sellerRef.id)
                        .get();

                if (userDoc.exists) {
                  final userData = userDoc.data()!;
                  sellerName =
                      '${userData['firstName']} ${userData['lastName']}';
                  sellerId = userData['userId'] ?? '';
                } else {
                  sellerName =
                      '${sellerData['firstName']} ${sellerData['lastName']}';
                  sellerId = sellerRef.id;
                }
              }
            }
          } catch (e) {
            sellerName = 'Unknown Seller';
            sellerId = sellerRef.id;
          }
        }

        final listing = AdminListingModel.fromMap(doc.id, {
          ...listingData,
          'sellerId': sellerId,
          'sellerName': sellerName,
        });

        listings.add(listing);
      }

      return listings;
    } catch (e) {
      throw Exception('Failed to fetch listings: $e');
    }
  }

  Future<void> removeListing(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'status': 'removed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove listing: $e');
    }
  }

  Future<List<AdminListingModel>> searchListings(String searchTerm) async {
    try {
      final titleQuery =
          await _firestore
              .collection('listings')
              .where('title', isGreaterThanOrEqualTo: searchTerm)
              .where('title', isLessThan: searchTerm + '\uf8ff')
              .limit(10)
              .get();

      final authorQuery =
          await _firestore
              .collection('listings')
              .where('author', isGreaterThanOrEqualTo: searchTerm)
              .where('author', isLessThan: searchTerm + '\uf8ff')
              .limit(10)
              .get();

      final Set<String> listingIds = {};
      final List<AdminListingModel> listings = [];

      for (final doc in [...titleQuery.docs, ...authorQuery.docs]) {
        if (!listingIds.contains(doc.id)) {
          listingIds.add(doc.id);

          final listingData = doc.data();

          String sellerName = 'Unknown';
          String sellerId = '';

          final sellerRef = listingData['sellerRef'] as DocumentReference?;
          if (sellerRef != null) {
            try {
              final sellerDoc = await sellerRef.get();
              if (sellerDoc.exists) {
                final sellerData = sellerDoc.data() as Map<String, dynamic>;

                if (listingData['sellerType'] == 'store') {
                  sellerName = sellerData['storeName'] ?? 'Unknown Store';
                  sellerId = sellerData['storeId'] ?? '';
                } else {
                  final userDoc =
                      await _firestore
                          .collection('users')
                          .doc(sellerData['ownerId'] ?? sellerRef.id)
                          .get();

                  if (userDoc.exists) {
                    final userData = userDoc.data()!;
                    sellerName =
                        '${userData['firstName']} ${userData['lastName']}';
                    sellerId = userData['userId'] ?? '';
                  } else {
                    sellerName =
                        '${sellerData['firstName']} ${sellerData['lastName']}';
                    sellerId = sellerRef.id;
                  }
                }
              }
            } catch (e) {
              sellerName = 'Unknown Seller';
              sellerId = sellerRef.id;
            }
          }

          final listing = AdminListingModel.fromMap(doc.id, {
            ...listingData,
            'sellerId': sellerId,
            'sellerName': sellerName,
          });

          listings.add(listing);
        }
      }

      return listings;
    } catch (e) {
      throw Exception('Failed to search listings: $e');
    }
  }

  Future<Map<String, int>> getStatistics() async {
    try {
      final futures = await Future.wait([
        _firestore.collection('users').count().get(), // All users
        _firestore.collection('stores').count().get(), // Store count
        _firestore.collection('listings').count().get(), // All listings count
        _firestore
            .collection('users')
            .where('isBlocked', isEqualTo: true)
            .count()
            .get(), // Blocked users
      ]);

      final allListingsSnapshot = await _firestore.collection('listings').get();
      int activeListingsCount = 0;

      for (final doc in allListingsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;

        if (status == null ||
            status.isEmpty ||
            status == 'active' ||
            (status != 'removed' && status != 'inactive' && status != 'sold')) {
          activeListingsCount++;
        }
      } // Get all users to count customers vs store owners
      final allUsersSnapshot = await _firestore.collection('users').get();
      int customerCount = 0;
      int storeOwnerCount = 0;

      for (final doc in allUsersSnapshot.docs) {
        final userData = doc.data();
        final user = AdminUserModel.fromMap(userData);

        if (user.isCustomer) {
          customerCount++;
        } else if (user.isStoreOwner) {
          storeOwnerCount++;
        }
      }
      return {
        'totalUsers': allUsersSnapshot.size, // Total users
        'totalCustomers': customerCount,
        'totalStoreOwners': storeOwnerCount,
        'totalStores': futures[1].count ?? 0,
        'totalListings':
            activeListingsCount, // Use our manually counted active listings
        'blockedUsers': futures[3].count ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch statistics: $e');
    }
  }
}
