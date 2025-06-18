import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStoreModel {
  final String storeId;
  final String ownerId;
  final String storeName;
  final String? description;
  final String ownerName;
  final String ownerEmail;
  final bool isVerified;
  final bool isBlocked;
  final double rating;
  final int totalRatings;
  final DateTime createdAt;
  final String? logoUrl;
  final List<String> categories;
  final int totalListings;

  AdminStoreModel({
    required this.storeId,
    required this.ownerId,
    required this.storeName,
    this.description,
    required this.ownerName,
    required this.ownerEmail,
    required this.isVerified,
    required this.isBlocked,
    required this.rating,
    required this.totalRatings,
    required this.createdAt,
    this.logoUrl,
    required this.categories,
    required this.totalListings,
  });

  factory AdminStoreModel.fromMap(Map<String, dynamic> map) {
    return AdminStoreModel(
      storeId: map['storeId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      storeName: map['storeName'] ?? '',
      description: map['description'],
      ownerName: map['ownerName'] ?? '',
      ownerEmail: map['ownerEmail'] ?? '',
      isVerified: map['isVerified'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      rating: (map['rating'] ?? 0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      logoUrl: map['logoUrl'],
      categories: List<String>.from(map['categories'] ?? []),
      totalListings: map['totalListings'] ?? 0,
    );
  }

  String get status {
    if (isBlocked) return 'Blocked';
    if (isVerified) return 'Verified';
    return 'Pending';
  }
}
