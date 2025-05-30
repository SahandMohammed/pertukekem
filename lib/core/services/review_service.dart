import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/listings/model/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final CollectionReference<ReviewModel> _reviewsRef;

  ReviewService() {
    _reviewsRef = _firestore
        .collection('reviews')
        .withConverter<ReviewModel>(
          fromFirestore: (snapshot, _) => ReviewModel.fromMap(snapshot.data()!),
          toFirestore: (review, _) => review.toMap(),
        );
  }

  /// Get all reviews for a specific listing
  Stream<List<ReviewModel>> getListingReviews(String listingId) {
    return _reviewsRef
        .where('listingId', isEqualTo: listingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Get review statistics for a listing
  Future<Map<String, dynamic>> getListingReviewStats(String listingId) async {
    final snapshot =
        await _reviewsRef.where('listingId', isEqualTo: listingId).get();

    if (snapshot.docs.isEmpty) {
      return {
        'totalReviews': 0,
        'averageRating': 0.0,
        'ratingDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      };
    }

    final reviews = snapshot.docs.map((doc) => doc.data()).toList();
    final totalReviews = reviews.length;
    final averageRating =
        reviews.map((r) => r.rating).reduce((a, b) => a + b) / totalReviews;

    final ratingDistribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in reviews) {
      final rating = review.rating.round();
      ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
    }

    return {
      'totalReviews': totalReviews,
      'averageRating': averageRating,
      'ratingDistribution': ratingDistribution,
    };
  }

  /// Add a new review
  Future<void> addReview({
    required String listingId,
    required double rating,
    required String comment,
    required String reviewerName,
    String? reviewerAvatar,
    bool isVerified = false,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Check if user has already reviewed this listing
    final existingReview =
        await _reviewsRef
            .where('listingId', isEqualTo: listingId)
            .where('reviewerId', isEqualTo: currentUser.uid)
            .get();

    if (existingReview.docs.isNotEmpty) {
      throw Exception('You have already reviewed this listing');
    }

    final now = DateTime.now();
    final reviewId = _reviewsRef.doc().id;

    final review = ReviewModel(
      reviewId: reviewId,
      listingId: listingId,
      reviewerId: currentUser.uid,
      reviewerName: reviewerName,
      reviewerAvatar: reviewerAvatar,
      rating: rating,
      comment: comment,
      createdAt: now,
      updatedAt: now,
      isVerified: isVerified,
    );

    await _reviewsRef.doc(reviewId).set(review);
  }

  /// Update review helpfulness
  Future<void> toggleReviewHelpfulness(String reviewId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final reviewDoc = await _reviewsRef.doc(reviewId).get();
    if (!reviewDoc.exists) {
      throw Exception('Review not found');
    }

    final review = reviewDoc.data()!;
    final helpfulBy = List<String>.from(review.helpfulBy);

    if (helpfulBy.contains(currentUser.uid)) {
      helpfulBy.remove(currentUser.uid);
    } else {
      helpfulBy.add(currentUser.uid);
    }

    await _reviewsRef.doc(reviewId).update({
      'helpfulBy': helpfulBy,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Add seller reply to a review
  Future<void> addSellerReply(String reviewId, String reply) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    await _reviewsRef.doc(reviewId).update({
      'replyFromSeller': reply,
      'replyDate': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Delete a review (only by the reviewer)
  Future<void> deleteReview(String reviewId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final reviewDoc = await _reviewsRef.doc(reviewId).get();
    if (!reviewDoc.exists) {
      throw Exception('Review not found');
    }

    final review = reviewDoc.data()!;
    if (review.reviewerId != currentUser.uid) {
      throw Exception('You can only delete your own reviews');
    }

    await _reviewsRef.doc(reviewId).delete();
  }
}
