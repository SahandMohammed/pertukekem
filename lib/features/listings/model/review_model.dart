import 'package:cloud_firestore/cloud_firestore.dart';

/// Review Model for listing reviews
class ReviewModel {
  final String reviewId; // Unique identifier for the review
  final String listingId; // ID of the listing being reviewed
  final String reviewerId; // UID of the user who wrote the review
  final String reviewerName; // Name of the reviewer
  final String? reviewerAvatar; // Profile image URL of the reviewer
  final double rating; // Rating given (1-5 stars)
  final String comment; // Written review comment
  final DateTime createdAt; // When the review was created
  final DateTime updatedAt; // Last update timestamp
  final bool isVerified; // Whether the reviewer is a verified purchaser
  final List<String> helpfulBy; // User IDs who found this review helpful
  final String? replyFromSeller; // Optional reply from the seller
  final DateTime? replyDate; // When the seller replied

  ReviewModel({
    required this.reviewId,
    required this.listingId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.helpfulBy = const [],
    this.replyFromSeller,
    this.replyDate,
  });

  /// Create a ReviewModel from a Firestore document
  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      reviewId: map['reviewId'] ?? '',
      listingId: map['listingId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? '',
      reviewerAvatar: map['reviewerAvatar'],
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isVerified: map['isVerified'] ?? false,
      helpfulBy: List<String>.from(map['helpfulBy'] ?? []),
      replyFromSeller: map['replyFromSeller'],
      replyDate:
          map['replyDate'] != null
              ? (map['replyDate'] as Timestamp).toDate()
              : null,
    );
  }

  /// Convert this ReviewModel to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'listingId': listingId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerAvatar': reviewerAvatar,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
      'helpfulBy': helpfulBy,
      'replyFromSeller': replyFromSeller,
      'replyDate': replyDate != null ? Timestamp.fromDate(replyDate!) : null,
    };
  }

  /// Create a copy of this ReviewModel with the given fields updated
  ReviewModel copyWith({
    String? reviewId,
    String? listingId,
    String? reviewerId,
    String? reviewerName,
    String? reviewerAvatar,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    List<String>? helpfulBy,
    String? replyFromSeller,
    DateTime? replyDate,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      listingId: listingId ?? this.listingId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerAvatar: reviewerAvatar ?? this.reviewerAvatar,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      helpfulBy: helpfulBy ?? this.helpfulBy,
      replyFromSeller: replyFromSeller ?? this.replyFromSeller,
      replyDate: replyDate ?? this.replyDate,
    );
  }
}
