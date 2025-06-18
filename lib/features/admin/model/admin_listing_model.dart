import 'package:cloud_firestore/cloud_firestore.dart';

class AdminListingModel {
  final String id;
  final String title;
  final String author;
  final double price;
  final String condition;
  final String sellerType;
  final String sellerId;
  final String sellerName;
  final String status;
  final String coverUrl;
  final DateTime createdAt;
  final String bookType;
  final List<String> category;

  AdminListingModel({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
    required this.condition,
    required this.sellerType,
    required this.sellerId,
    required this.sellerName,
    required this.status,
    required this.coverUrl,
    required this.createdAt,
    required this.bookType,
    required this.category,
  });

  factory AdminListingModel.fromMap(String id, Map<String, dynamic> map) {
    return AdminListingModel(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      condition: map['condition'] ?? '',
      sellerType: map['sellerType'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      status: map['status'] ?? 'active',
      coverUrl: map['coverUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bookType: map['bookType'] ?? 'physical',
      category: List<String>.from(map['category'] ?? []),
    );
  }

  String get formattedPrice => 'RM ${price.toStringAsFixed(2)}';

  String get statusText {
    switch (status) {
      case 'active':
        return 'Active';
      case 'sold':
        return 'Sold';
      case 'inactive':
        return 'Inactive';
      case 'removed':
        return 'Removed';
      default:
        return status;
    }
  }
}
