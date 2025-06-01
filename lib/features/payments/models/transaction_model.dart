import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String id;
  final String transactionId;
  final String buyerId;
  final String sellerId;
  final String listingId;
  final String listingTitle;
  final double amount;
  final String paymentMethod;
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? paymentDetails; // Store payment-specific info
  final String? orderId; // Link to order if exists

  Transaction({
    required this.id,
    required this.transactionId,
    required this.buyerId,
    required this.sellerId,
    required this.listingId,
    required this.listingTitle,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.paymentDetails,
    this.orderId,
  });

  // Factory constructor to create Transaction from Firestore document
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      transactionId: data['transactionId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      listingId: data['listingId'] ?? '',
      listingTitle: data['listingTitle'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt:
          data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
      paymentDetails: data['paymentDetails'],
      orderId: data['orderId'],
    );
  }

  // Convert Transaction to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'transactionId': transactionId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'paymentDetails': paymentDetails,
      'orderId': orderId,
    };
  }

  // Copy with method for updating transaction
  Transaction copyWith({
    String? id,
    String? transactionId,
    String? buyerId,
    String? sellerId,
    String? listingId,
    String? listingTitle,
    double? amount,
    String? paymentMethod,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? paymentDetails,
    String? orderId,
  }) {
    return Transaction(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      orderId: orderId ?? this.orderId,
    );
  }

  @override
  String toString() {
    return 'Transaction{id: $id, transactionId: $transactionId, amount: $amount, status: $status}';
  }
}
