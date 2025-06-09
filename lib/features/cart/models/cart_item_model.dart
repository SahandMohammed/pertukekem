import 'package:cloud_firestore/cloud_firestore.dart';
import '../../listings/model/listing_model.dart';

class CartItem {
  final String id;
  final String userId;
  final Listing listing;
  final int quantity;
  final Timestamp addedAt;

  CartItem({
    required this.id,
    required this.userId,
    required this.listing,
    required this.quantity,
    required this.addedAt,
  });
  factory CartItem.fromMap(Map<String, dynamic> map, String id) {
    return CartItem(
      id: id,
      userId: map['userId'] ?? '',
      listing: Listing.fromFirestore(
        // Create a mock DocumentSnapshot for fromFirestore method
        MockDocumentSnapshot(map['listing'] ?? {}, id),
        null,
      ),
      quantity: map['quantity'] ?? 1,
      addedAt: map['addedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'listing': listing.toFirestore(),
      'quantity': quantity,
      'addedAt': addedAt,
    };
  }

  double get totalPrice => listing.price * quantity;

  CartItem copyWith({
    String? id,
    String? userId,
    Listing? listing,
    int? quantity,
    Timestamp? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      listing: listing ?? this.listing,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

class Cart {
  final String userId;
  final List<CartItem> items;
  final Timestamp updatedAt;

  Cart({required this.userId, required this.items, required this.updatedAt});

  double get totalAmount =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  Cart copyWith({String? userId, List<CartItem>? items, Timestamp? updatedAt}) {
    return Cart(
      userId: userId ?? this.userId,
      items: items ?? this.items,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Mock DocumentSnapshot for serialization
class MockDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  final String _id;

  MockDocumentSnapshot(this._data, this._id);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  String get id => _id;

  @override
  bool get exists => true;

  @override
  SnapshotMetadata get metadata => MockSnapshotMetadata();

  @override
  DocumentReference<Map<String, dynamic>> get reference =>
      throw UnimplementedError();

  @override
  dynamic operator [](Object field) => _data[field];

  @override
  dynamic get(Object field) => _data[field];
}

class MockSnapshotMetadata implements SnapshotMetadata {
  @override
  bool get hasPendingWrites => false;

  @override
  bool get isFromCache => false;
}
