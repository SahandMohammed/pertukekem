import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/store_rating_model.dart';

class StoreRatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit or update a rating for a store
  Future<void> submitRating({
    required String storeId,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get user data for display purposes
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      final storeRating = StoreRating(
        id: user.uid, // Use userId as document ID to prevent duplicates
        userId: user.uid,
        storeId: storeId,
        rating: rating,
        comment: comment,
        timestamp: DateTime.now(),
        userName: userData?['firstName'] ?? 'Anonymous',
        userProfilePicture: userData?['profilePicture'],
      );

      // Write rating to subcollection
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('ratings')
          .doc(user.uid)
          .set(storeRating.toFirestore());

      // Update store aggregate data
      await _updateStoreAggregates(storeId);
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }

  // Get user's rating for a specific store
  Future<StoreRating?> getUserRating(String storeId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc =
          await _firestore
              .collection('stores')
              .doc(storeId)
              .collection('ratings')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        return StoreRating.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user rating: $e');
    }
  }

  // Stream all ratings for a store
  Stream<List<StoreRating>> getStoreRatings(String storeId) {
    return _firestore
        .collection('stores')
        .doc(storeId)
        .collection('ratings')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => StoreRating.fromFirestore(doc))
                  .toList(),
        );
  }

  // Delete a user's rating
  Future<void> deleteRating(String storeId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('ratings')
          .doc(user.uid)
          .delete();

      // Update store aggregate data
      await _updateStoreAggregates(storeId);
    } catch (e) {
      throw Exception('Failed to delete rating: $e');
    }
  }

  // Update store aggregate rating data
  Future<void> _updateStoreAggregates(String storeId) async {
    try {
      final ratingsSnapshot =
          await _firestore
              .collection('stores')
              .doc(storeId)
              .collection('ratings')
              .get();

      if (ratingsSnapshot.docs.isEmpty) {
        // No ratings, reset to defaults
        await _firestore.collection('stores').doc(storeId).update({
          'rating': 0.0,
          'totalRatings': 0,
        });
        return;
      }

      // Calculate new averages
      double totalRating = 0.0;
      int ratingCount = ratingsSnapshot.docs.length;

      for (final doc in ratingsSnapshot.docs) {
        final data = doc.data();
        totalRating += (data['rating'] ?? 0.0).toDouble();
      }

      final avgRating = totalRating / ratingCount;

      // Update store document
      await _firestore.collection('stores').doc(storeId).update({
        'rating': double.parse(avgRating.toStringAsFixed(1)),
        'totalRatings': ratingCount,
      });
    } catch (e) {
      throw Exception('Failed to update store aggregates: $e');
    }
  }

  // Get store rating statistics
  Future<Map<String, dynamic>> getStoreRatingStats(String storeId) async {
    try {
      final ratingsSnapshot =
          await _firestore
              .collection('stores')
              .doc(storeId)
              .collection('ratings')
              .get();

      if (ratingsSnapshot.docs.isEmpty) {
        return {
          'avgRating': 0.0,
          'totalRatings': 0,
          'ratingDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        };
      }

      double totalRating = 0.0;
      Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

      for (final doc in ratingsSnapshot.docs) {
        final data = doc.data();
        final rating = (data['rating'] ?? 0.0).toDouble();
        totalRating += rating;

        // Count distribution (round to nearest star)
        final starRating = rating.round();
        if (starRating >= 1 && starRating <= 5) {
          distribution[starRating] = (distribution[starRating] ?? 0) + 1;
        }
      }

      return {
        'avgRating': totalRating / ratingsSnapshot.docs.length,
        'totalRatings': ratingsSnapshot.docs.length,
        'ratingDistribution': distribution,
      };
    } catch (e) {
      throw Exception('Failed to get rating stats: $e');
    }
  }
}
