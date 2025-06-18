import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  // Store notifications
  newOrder,
  orderCancelled,
  orderUpdate,
  lowStock,
  review,
  system,

  // Customer notifications
  orderConfirmed,
  orderShipped,
  orderDelivered,
  orderRefunded,
  newBookAvailable,
  promotionalOffer,
  systemUpdate,
  libraryUpdate,
  paymentReminder,
}

enum NotificationTarget { store, customer }

class UnifiedNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationTarget target;
  final bool isRead;
  final Timestamp createdAt;

  // Store-specific fields
  final String? storeId;

  // Customer-specific fields
  final String? customerId;

  // Shared metadata
  final Map<String, dynamic>? metadata;
  final String? imageUrl;
  final String? actionUrl;

  UnifiedNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.target,
    required this.isRead,
    required this.createdAt,
    this.storeId,
    this.customerId,
    this.metadata,
    this.imageUrl,
    this.actionUrl,
  }) : assert(
         (target == NotificationTarget.store && storeId != null) ||
             (target == NotificationTarget.customer && customerId != null),
         'storeId must be provided for store notifications, customerId for customer notifications',
       );

  factory UnifiedNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return UnifiedNotification(
      id: snapshot.id,
      title: data['title'] as String,
      message: data['message'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      target: NotificationTarget.values.firstWhere(
        (e) => e.name == data['target'],
        orElse: () => NotificationTarget.store,
      ),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp,
      storeId: data['storeId'] as String?,
      customerId: data['customerId'] as String?,
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
      'target': target.name,
      'isRead': isRead,
      'createdAt': createdAt,
      'storeId': storeId,
      'customerId': customerId,
      'metadata': metadata,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  UnifiedNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationTarget? target,
    bool? isRead,
    Timestamp? createdAt,
    String? storeId,
    String? customerId,
    Map<String, dynamic>? metadata,
    String? imageUrl,
    String? actionUrl,
  }) {
    return UnifiedNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      target: target ?? this.target,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      storeId: storeId ?? this.storeId,
      customerId: customerId ?? this.customerId,
      metadata: metadata ?? this.metadata,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  // Helper method to get notification icon based on type
  String get iconPath {
    switch (type) {
      case NotificationType.newOrder:
      case NotificationType.orderConfirmed:
      case NotificationType.orderShipped:
      case NotificationType.orderDelivered:
        return 'assets/icons/order.png';
      case NotificationType.orderCancelled:
      case NotificationType.orderRefunded:
        return 'assets/icons/order_cancelled.png';
      case NotificationType.newBookAvailable:
      case NotificationType.libraryUpdate:
        return 'assets/icons/book.png';
      case NotificationType.promotionalOffer:
        return 'assets/icons/offer.png';
      case NotificationType.paymentReminder:
        return 'assets/icons/payment.png';
      case NotificationType.review:
        return 'assets/icons/review.png';
      case NotificationType.lowStock:
        return 'assets/icons/inventory.png';
      case NotificationType.system:
      case NotificationType.systemUpdate:
      case NotificationType.orderUpdate:
        return 'assets/icons/system.png';
    }
  }

  // Helper method to get notification color based on type
  int get colorValue {
    switch (type) {
      case NotificationType.newOrder:
      case NotificationType.orderConfirmed:
      case NotificationType.orderShipped:
      case NotificationType.orderDelivered:
        return 0xFF4CAF50; // Green
      case NotificationType.orderCancelled:
      case NotificationType.orderRefunded:
        return 0xFFF44336; // Red
      case NotificationType.newBookAvailable:
      case NotificationType.libraryUpdate:
        return 0xFF2196F3; // Blue
      case NotificationType.promotionalOffer:
        return 0xFFFF9800; // Orange
      case NotificationType.paymentReminder:
        return 0xFFE91E63; // Pink
      case NotificationType.review:
        return 0xFF9C27B0; // Purple
      case NotificationType.lowStock:
        return 0xFFFF5722; // Deep Orange
      case NotificationType.orderUpdate:
        return 0xFF03DAC6; // Teal
      case NotificationType.system:
      case NotificationType.systemUpdate:
        return 0xFF9E9E9E; // Grey
    }
  }
}
