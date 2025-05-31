import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newOrder,
  orderCancelled,
  orderUpdate,
  lowStock,
  review,
  system,
}

class StoreNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final Timestamp createdAt;
  final Map<String, dynamic>? metadata;

  StoreNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  });

  factory StoreNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return StoreNotification(
      id: snapshot.id,
      title: data['title'] as String,
      message: data['message'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt,
      'metadata': metadata,
    };
  }

  StoreNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    Timestamp? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return StoreNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
