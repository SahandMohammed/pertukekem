import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../listings/model/listing_model.dart';
import '../../store/models/store_model.dart';

class CustomerHomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get recently listed items (from last 30 days, sorted by creation date)
  Future<List<Listing>> getRecentlyListedItems({int limit = 10}) async {
    try {
      // Calculate the date 30 days ago
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final thirtyDaysAgoTimestamp = Timestamp.fromDate(thirtyDaysAgo);

      final querySnapshot =
          await _firestore
              .collection('listings')
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: thirtyDaysAgoTimestamp,
              )
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();
      return querySnapshot.docs.map((doc) {
        return Listing.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>,
          null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch recently listed items: $e');
    }
  }

  /// Get recently joined stores (from last 30 days, sorted by creation date)
  Future<List<StoreModel>> getRecentlyJoinedStores({int limit = 10}) async {
    try {
      // Calculate the date 30 days ago
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final thirtyDaysAgoTimestamp = Timestamp.fromDate(thirtyDaysAgo);

      final querySnapshot =
          await _firestore
              .collection('stores')
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: thirtyDaysAgoTimestamp,
              )
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return StoreModel.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch recently joined stores: $e');
    }
  }

  /// Search listings by title, author, or category
  Future<List<Listing>> searchListings(String query, {int limit = 20}) async {
    try {
      if (query.isEmpty) return [];

      // Firestore doesn't support full-text search, so we'll search by title and author
      // For a production app, consider using Algolia or Elasticsearch
      final titleResults =
          await _firestore
              .collection('listings')
              .where('title', isGreaterThanOrEqualTo: query)
              .where('title', isLessThanOrEqualTo: query + '\uf8ff')
              .limit(limit ~/ 2)
              .get();

      final authorResults =
          await _firestore
              .collection('listings')
              .where('author', isGreaterThanOrEqualTo: query)
              .where('author', isLessThanOrEqualTo: query + '\uf8ff')
              .limit(limit ~/ 2)
              .get();

      final Set<String> seenIds = {};
      final List<Listing> allResults = [];

      // Combine results and remove duplicates
      for (final doc in [...titleResults.docs, ...authorResults.docs]) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          allResults.add(
            Listing.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
              null,
            ),
          );
        }
      }

      return allResults;
    } catch (e) {
      throw Exception('Failed to search listings: $e');
    }
  }

  /// Get all listings with optional filters
  Stream<List<Listing>> getAllListings({
    String? condition,
    String? category,
    int limit = 50,
  }) {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('listings');

      if (condition != null) {
        query = query.where('condition', isEqualTo: condition);
      }

      if (category != null) {
        query = query.where('category', arrayContains: category);
      }

      return query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return Listing.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
                null,
              );
            }).toList();
          });
    } catch (e) {
      throw Exception('Failed to get all listings: $e');
    }
  }

  /// Get all stores
  Future<List<StoreModel>> getAllStores({int limit = 50}) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('stores')
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return StoreModel.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch stores: $e');
    }
  }
}
