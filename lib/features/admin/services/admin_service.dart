import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/admin_user_model.dart';
import '../model/admin_store_model.dart';
import '../model/admin_listing_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Users Management
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
      // Search by name
      final nameQuery =
          await _firestore
              .collection('users')
              .where('firstName', isGreaterThanOrEqualTo: searchTerm)
              .where('firstName', isLessThan: searchTerm + '\uf8ff')
              .limit(10)
              .get();

      // Search by email
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

      // Combine results and remove duplicates
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

  // Stores Management
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

        // Get owner information
        final ownerDoc =
            await _firestore
                .collection('users')
                .doc(storeData['ownerId'])
                .get();

        if (ownerDoc.exists) {
          final ownerData = ownerDoc.data()!;

          // Get total listings count
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

      // Update store owner's blocked status
      batch.update(_firestore.collection('users').doc(ownerId), {
        'isBlocked': isBlocked,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If blocking, also deactivate all store listings
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

        // Get owner information
        final ownerDoc =
            await _firestore
                .collection('users')
                .doc(storeData['ownerId'])
                .get();

        if (ownerDoc.exists) {
          final ownerData = ownerDoc.data()!;

          // Get total listings count
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

  // Listings Management
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

        // Get seller information
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
                // Get user data for individual sellers
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
            // If there's an error getting seller info, use default values
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
      // Search by title
      final titleQuery =
          await _firestore
              .collection('listings')
              .where('title', isGreaterThanOrEqualTo: searchTerm)
              .where('title', isLessThan: searchTerm + '\uf8ff')
              .limit(10)
              .get();

      // Search by author
      final authorQuery =
          await _firestore
              .collection('listings')
              .where('author', isGreaterThanOrEqualTo: searchTerm)
              .where('author', isLessThan: searchTerm + '\uf8ff')
              .limit(10)
              .get();

      final Set<String> listingIds = {};
      final List<AdminListingModel> listings = [];

      // Combine results and remove duplicates
      for (final doc in [...titleQuery.docs, ...authorQuery.docs]) {
        if (!listingIds.contains(doc.id)) {
          listingIds.add(doc.id);

          final listingData = doc.data();

          // Get seller information
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
                  // Get user data for individual sellers
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
              // If there's an error getting seller info, use default values
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

  // Statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      final futures = await Future.wait([
        _firestore.collection('users').count().get(),
        _firestore.collection('stores').count().get(),
        _firestore
            .collection('listings')
            .where('status', isEqualTo: 'active')
            .count()
            .get(),
        _firestore
            .collection('users')
            .where('isBlocked', isEqualTo: true)
            .count()
            .get(),
      ]);
      return {
        'totalUsers': futures[0].count ?? 0,
        'totalStores': futures[1].count ?? 0,
        'totalListings': futures[2].count ?? 0,
        'blockedUsers': futures[3].count ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch statistics: $e');
    }
  }
}
