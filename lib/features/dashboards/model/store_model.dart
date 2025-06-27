import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String storeId; // Unique identifier for the store
  final String ownerId; // UID of the user who owns the store
  final String storeName; // Store name (must be unique if public)
  final String? description; // Short summary of the store (optional)
  final Map<String, dynamic>? storeAddress; // Detailed address structure
  final List<Map<String, String>>
  contactInfo; // List of contact methods (phone, email)
  final double rating; // Average rating of the store
  final int totalRatings; // Count of ratings for computing averages
  final DateTime createdAt; // When the store was created
  final DateTime updatedAt; // Last update timestamp
  final String? logoUrl; // URL to store logo image
  final String? bannerUrl; // URL to store banner image
  final bool isVerified; // Whether the store is verified by admin
  final List<String> categories; // Categories of products sold by the store
  final Map<String, dynamic>? businessHours; // Opening and closing hours
  final Map<String, dynamic>? socialMedia; // Social media links

  StoreModel({
    required this.storeId,
    required this.ownerId,
    required this.storeName,
    this.description,
    this.storeAddress,
    required this.contactInfo,
    this.rating = 0.0,
    this.totalRatings = 0,
    required this.createdAt,
    required this.updatedAt,
    this.logoUrl,
    this.bannerUrl,
    this.isVerified = false,
    this.categories = const [],
    this.businessHours,
    this.socialMedia,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map) {
    return StoreModel(
      storeId: map['storeId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      storeName: map['storeName'] ?? '',
      description: map['description'],
      storeAddress: map['storeAddress'],
      contactInfo: List<Map<String, String>>.from(
        (map['contactInfo'] ?? []).map(
          (contact) => Map<String, String>.from(contact),
        ),
      ),
      rating: (map['rating'] ?? 0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      logoUrl: map['logoUrl'],
      bannerUrl: map['bannerUrl'],
      isVerified: map['isVerified'] ?? false,
      categories: List<String>.from(map['categories'] ?? []),
      businessHours: map['businessHours'],
      socialMedia: map['socialMedia'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'ownerId': ownerId,
      'storeName': storeName,
      'description': description,
      'storeAddress': storeAddress,
      'contactInfo': contactInfo,
      'rating': rating,
      'totalRatings': totalRatings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'isVerified': isVerified,
      'categories': categories,
      'businessHours': businessHours,
      'socialMedia': socialMedia,
    };
  }

  StoreModel copyWith({
    String? storeId,
    String? ownerId,
    String? storeName,
    String? description,
    Map<String, dynamic>? storeAddress,
    List<Map<String, String>>? contactInfo,
    double? rating,
    int? totalRatings,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? logoUrl,
    String? bannerUrl,
    bool? isVerified,
    List<String>? categories,
    Map<String, dynamic>? businessHours,
    Map<String, dynamic>? socialMedia,
  }) {
    return StoreModel(
      storeId: storeId ?? this.storeId,
      ownerId: ownerId ?? this.ownerId,
      storeName: storeName ?? this.storeName,
      description: description ?? this.description,
      storeAddress: storeAddress ?? this.storeAddress,
      contactInfo: contactInfo ?? this.contactInfo,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      isVerified: isVerified ?? this.isVerified,
      categories: categories ?? this.categories,
      businessHours: businessHours ?? this.businessHours,
      socialMedia: socialMedia ?? this.socialMedia,
    );
  }
}
