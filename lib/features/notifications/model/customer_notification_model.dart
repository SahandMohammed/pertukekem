import 'package:cloud_firestore/cloud_firestore.dart';

enum CustomerNotificationType {
  orderConfirmed,
  orderShipped,
  orderDelivered,
  orderCancelled,
  orderRefunded,
  newBookAvailable,
  promotionalOffer,
  systemUpdate,
  libraryUpdate,
  paymentReminder,
}

class CustomerNotification {
  final String id;
  final String title;
  final String message;
  final CustomerNotificationType type;
  final bool isRead;
  final Timestamp createdAt;
  final String customerId;
  final Map<String, dynamic>? metadata;
  final String? imageUrl;
  final String? actionUrl;

  CustomerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.customerId,
    this.metadata,
    this.imageUrl,
    this.actionUrl,
  });

  factory CustomerNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return CustomerNotification(
      id: snapshot.id,
      title: data['title'] as String,
      message: data['message'] as String,
      type: CustomerNotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => CustomerNotificationType.systemUpdate,
      ),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp,
      customerId: data['customerId'] as String,
      metadata: data['metadata'] as Map<String, dynamic>?,
      imageUrl: data['imageUrl'] as String?,
      actionUrl: data['actionUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt,
      'customerId': customerId,
      'metadata': metadata,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  CustomerNotification copyWith({
    String? id,
    String? title,
    String? message,
    CustomerNotificationType? type,
    bool? isRead,
    Timestamp? createdAt,
    String? customerId,
    Map<String, dynamic>? metadata,
    String? imageUrl,
    String? actionUrl,
  }) {
    return CustomerNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      customerId: customerId ?? this.customerId,
      metadata: metadata ?? this.metadata,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  // Helper method to get notification icon based on type
  String get iconPath {
    switch (type) {
      case CustomerNotificationType.orderConfirmed:
      case CustomerNotificationType.orderShipped:
      case CustomerNotificationType.orderDelivered:
        return 'assets/icons/order.png';
      case CustomerNotificationType.orderCancelled:
      case CustomerNotificationType.orderRefunded:
        return 'assets/icons/order_cancelled.png';
      case CustomerNotificationType.newBookAvailable:
      case CustomerNotificationType.libraryUpdate:
        return 'assets/icons/book.png';
      case CustomerNotificationType.promotionalOffer:
        return 'assets/icons/offer.png';
      case CustomerNotificationType.paymentReminder:
        return 'assets/icons/payment.png';
      case CustomerNotificationType.systemUpdate:
        return 'assets/icons/system.png';
    }
  }

  // Helper method to get notification color based on type
  int get colorValue {
    switch (type) {
      case CustomerNotificationType.orderConfirmed:
      case CustomerNotificationType.orderShipped:
      case CustomerNotificationType.orderDelivered:
        return 0xFF4CAF50; // Green
      case CustomerNotificationType.orderCancelled:
      case CustomerNotificationType.orderRefunded:
        return 0xFFF44336; // Red
      case CustomerNotificationType.newBookAvailable:
      case CustomerNotificationType.libraryUpdate:
        return 0xFF2196F3; // Blue
      case CustomerNotificationType.promotionalOffer:
        return 0xFFFF9800; // Orange
      case CustomerNotificationType.paymentReminder:
        return 0xFFE91E63; // Pink
      case CustomerNotificationType.systemUpdate:
        return 0xFF9E9E9E; // Grey
    }
  }
}
