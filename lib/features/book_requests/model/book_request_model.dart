import 'package:cloud_firestore/cloud_firestore.dart';

enum BookRequestStatus {
  pending,
  accepted,
  rejected,
  fulfilled,
  cancelled,
}

class BookRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String storeId;
  final String storeName;
  final String bookTitle;
  final String? note;
  final BookRequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? storeResponse;
  final DateTime? responseDate;

  BookRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.storeId,
    required this.storeName,
    required this.bookTitle,
    this.note,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.storeResponse,
    this.responseDate,
  });

  factory BookRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookRequest(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? '',
      bookTitle: data['bookTitle'] ?? '',
      note: data['note'],
      status: BookRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      storeResponse: data['storeResponse'],
      responseDate: data['responseDate'] != null
          ? (data['responseDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'storeId': storeId,
      'storeName': storeName,
      'bookTitle': bookTitle,
      'note': note,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'storeResponse': storeResponse,
      'responseDate':
          responseDate != null ? Timestamp.fromDate(responseDate!) : null,
    };
  }

  BookRequest copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? storeId,
    String? storeName,
    String? bookTitle,
    String? note,
    BookRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? storeResponse,
    DateTime? responseDate,
  }) {
    return BookRequest(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      bookTitle: bookTitle ?? this.bookTitle,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      storeResponse: storeResponse ?? this.storeResponse,
      responseDate: responseDate ?? this.responseDate,
    );
  }

  String get statusDisplayText {
    switch (status) {
      case BookRequestStatus.pending:
        return 'Pending';
      case BookRequestStatus.accepted:
        return 'Accepted';
      case BookRequestStatus.rejected:
        return 'Rejected';
      case BookRequestStatus.fulfilled:
        return 'Fulfilled';
      case BookRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get canBeCancelled => status == BookRequestStatus.pending;
}
