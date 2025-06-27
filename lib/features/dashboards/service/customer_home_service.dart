import 'package:cloud_firestore/cloud_firestore.dart';
import '../../listings/model/listing_model.dart';
import '../model/store_model.dart';

class CustomerHomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Listing>> getRecentlyListedItems({int limit = 10}) async {
    try {
      print('DEBUG: Fetching recent listings from stores only...');
      print('DEBUG: Limit set to: $limit');

      final querySnapshot =
          await _firestore
              .collection('listings')
              .where(
                'sellerType',
                isEqualTo: 'store',
              ) // Only show store listings
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      print('DEBUG: Found ${querySnapshot.docs.length} recent store listings');

      final listings =
          querySnapshot.docs.map((doc) {
            return Listing.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
              null,
            );
          }).toList();

      for (final listing in listings) {
        final listingDate = listing.createdAt?.toDate();
        print('DEBUG: Store Listing ${listing.id}: ${listing.title}');
        print(
          'DEBUG:   - Created: ${listing.createdAt} (${listingDate ?? 'No date'})',
        );
        print('DEBUG:   - Seller Type: ${listing.sellerType}');
      }

      return listings;
    } catch (e) {
      print('DEBUG: Error in getRecentlyListedItems: $e');
      throw Exception('Failed to fetch recently listed items from stores: $e');
    }
  }

  Future<List<StoreModel>> getRecentlyJoinedStores({int limit = 10}) async {
    try {
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

  Future<List<Listing>> searchListings(
    String query, {
    int limit = 20,
    String? condition,
  }) async {
    try {
      if (query.isEmpty) return [];

      print('DEBUG: Searching for query: "$query"');

      final lowerQuery = query.toLowerCase();
      print('DEBUG: Using lowercase query: "$lowerQuery"');

      final allListingsSnapshot =
          await _firestore
              .collection('listings')
              .limit(100) // Increased limit to get more comprehensive results
              .get();

      print(
        'DEBUG: Total listings in database: ${allListingsSnapshot.docs.length}',
      );

      final List<Listing> matchingResults = [];

      for (final doc in allListingsSnapshot.docs) {
        final data = doc.data();
        final title = (data['title'] as String? ?? '').toLowerCase();
        final author = (data['author'] as String? ?? '').toLowerCase();
        final isbn = (data['isbn'] as String? ?? '').toLowerCase();
        final description =
            (data['description'] as String? ?? '').toLowerCase();

        final categories =
            (data['category'] as List<dynamic>? ?? [])
                .map((cat) => cat.toString().toLowerCase())
                .toList();

        final bookCondition =
            (data['condition'] as String? ?? '').toLowerCase();

        final bool queryMatches =
            title.contains(lowerQuery) ||
            author.contains(lowerQuery) ||
            isbn.contains(lowerQuery) ||
            description.contains(lowerQuery) ||
            categories.any((cat) => cat.contains(lowerQuery));

        final bool conditionMatches =
            condition == null || bookCondition == condition.toLowerCase();

        if (queryMatches && conditionMatches) {
          final listing = Listing.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>,
            null,
          );
          matchingResults.add(listing);
          print('DEBUG: Found match: "${listing.title}" by ${listing.author}');
        }
      }

      matchingResults.sort((a, b) {
        final aTitle = a.title.toLowerCase();
        final bTitle = b.title.toLowerCase();
        final aAuthor = a.author.toLowerCase();
        final bAuthor = b.author.toLowerCase();

        if (aTitle == lowerQuery && bTitle != lowerQuery) return -1;
        if (bTitle == lowerQuery && aTitle != lowerQuery) return 1;

        if (aAuthor == lowerQuery && bAuthor != lowerQuery) return -1;
        if (bAuthor == lowerQuery && aAuthor != lowerQuery) return 1;

        if (aTitle.startsWith(lowerQuery) && !bTitle.startsWith(lowerQuery))
          return -1;
        if (bTitle.startsWith(lowerQuery) && !aTitle.startsWith(lowerQuery))
          return 1;

        if (aAuthor.startsWith(lowerQuery) && !bAuthor.startsWith(lowerQuery))
          return -1;
        if (bAuthor.startsWith(lowerQuery) && !aAuthor.startsWith(lowerQuery))
          return 1;

        return aTitle.compareTo(bTitle);
      });

      final limitedResults = matchingResults.take(limit).toList();

      print('DEBUG: Total search results: ${limitedResults.length}');
      for (final result in limitedResults) {
        print('DEBUG: Result: "${result.title}" by ${result.author}');
      }

      return limitedResults;
    } catch (e) {
      print('DEBUG: Search error: $e');
      throw Exception('Failed to search listings: $e');
    }
  }

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
