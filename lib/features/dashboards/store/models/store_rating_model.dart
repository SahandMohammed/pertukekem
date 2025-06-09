import 'package:cloud_firestore/cloud_firestore.dart';

class StoreRating {
  final String id;
  final String userId;
  final String storeId;
  final double rating;
  final String comment;
  final DateTime timestamp;
  final String? userName;
  final String? userProfilePicture;

  StoreRating({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.rating,
    required this.comment,
    required this.timestamp,
    this.userName,
    this.userProfilePicture,
  });

  factory StoreRating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreRating(
      id: doc.id,
      userId: data['userId'] ?? '',
      storeId: data['storeId'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userName: data['userName'],
      userProfilePicture: data['userProfilePicture'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'storeId': storeId,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
      'userName': userName,
      'userProfilePicture': userProfilePicture,
    };
  }

  StoreRating copyWith({
    String? id,
    String? userId,
    String? storeId,
    double? rating,
    String? comment,
    DateTime? timestamp,
    String? userName,
    String? userProfilePicture,
  }) {
    return StoreRating(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      timestamp: timestamp ?? this.timestamp,
      userName: userName ?? this.userName,
      userProfilePicture: userProfilePicture ?? this.userProfilePicture,
    );
  }
}
