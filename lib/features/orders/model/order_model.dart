import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, confirmed, shipped, delivered, cancelled, rejected }

class Order {
  final String id;
  final DocumentReference buyerRef;
  final DocumentReference sellerRef;
  final DocumentReference listingRef;
  final double totalAmount;
  final int quantity;
  final OrderStatus status;
  final String? shippingAddress;
  final String? trackingNumber;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  Order({
    required this.id,
    required this.buyerRef,
    required this.sellerRef,
    required this.listingRef,
    required this.totalAmount,
    required this.quantity,
    required this.status,
    this.shippingAddress,
    this.trackingNumber,
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Order(
      id: snapshot.id,
      buyerRef: data['buyerRef'] as DocumentReference,
      sellerRef: data['sellerRef'] as DocumentReference,
      listingRef: data['listingRef'] as DocumentReference,
      totalAmount: (data['totalAmount'] as num).toDouble(),
      quantity: data['quantity'] as int,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      shippingAddress: data['shippingAddress'] as String?,
      trackingNumber: data['trackingNumber'] as String?,
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'buyerRef': buyerRef,
      'sellerRef': sellerRef,
      'listingRef': listingRef,
      'totalAmount': totalAmount,
      'quantity': quantity,
      'status': status.name,
      if (shippingAddress != null) 'shippingAddress': shippingAddress,
      if (trackingNumber != null) 'trackingNumber': trackingNumber,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Order copyWith({
    String? id,
    DocumentReference? buyerRef,
    DocumentReference? sellerRef,
    DocumentReference? listingRef,
    double? totalAmount,
    int? quantity,
    OrderStatus? status,
    String? shippingAddress,
    String? trackingNumber,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      buyerRef: buyerRef ?? this.buyerRef,
      sellerRef: sellerRef ?? this.sellerRef,
      listingRef: listingRef ?? this.listingRef,
      totalAmount: totalAmount ?? this.totalAmount,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
