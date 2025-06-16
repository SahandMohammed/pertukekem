import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/customer_notification_model.dart';

class NotificationDetailScreen extends StatelessWidget {
  final CustomerNotification notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final createdAt = notification.createdAt.toDate();
    final formattedDate = DateFormat.yMMMd().add_jm().format(createdAt);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Notification',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Color(notification.colorValue).withOpacity(0.1),
                      Color(notification.colorValue).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(
                              notification.colorValue,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            _getNotificationIcon(notification.type),
                            color: Color(notification.colorValue),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getNotificationTypeLabel(notification.type),
                                style: TextStyle(
                                  color: Color(notification.colorValue),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Message Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Metadata Card (if available)
            if (notification.metadata != null &&
                notification.metadata!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildMetadataItems(),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Button (if actionUrl is available)
            if (notification.actionUrl != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleAction(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(notification.colorValue),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    _getActionButtonText(notification.type),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMetadataItems() {
    if (notification.metadata == null) return [];

    final items = <Widget>[];
    final metadata = notification.metadata!;

    metadata.forEach((key, value) {
      if (value != null) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    _formatMetadataKey(key),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _formatMetadataValue(key, value),
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    return items;
  }

  String _formatMetadataKey(String key) {
    switch (key) {
      case 'orderId':
        return 'Order ID:';
      case 'orderNumber':
        return 'Order #:';
      case 'totalAmount':
        return 'Amount:';
      case 'storeName':
        return 'Store:';
      case 'trackingNumber':
        return 'Tracking:';
      case 'bookTitle':
        return 'Book:';
      case 'author':
        return 'Author:';
      case 'customerName':
        return 'Customer:';
      default:
        return '${key.substring(0, 1).toUpperCase()}${key.substring(1)}:';
    }
  }

  String _formatMetadataValue(String key, dynamic value) {
    if (key == 'totalAmount' && value is num) {
      return '\$${value.toStringAsFixed(2)}';
    }
    return value.toString();
  }

  IconData _getNotificationIcon(CustomerNotificationType type) {
    switch (type) {
      case CustomerNotificationType.orderConfirmed:
        return Icons.check_circle;
      case CustomerNotificationType.orderShipped:
        return Icons.local_shipping;
      case CustomerNotificationType.orderDelivered:
        return Icons.home;
      case CustomerNotificationType.orderCancelled:
      case CustomerNotificationType.orderRefunded:
        return Icons.cancel;
      case CustomerNotificationType.newBookAvailable:
      case CustomerNotificationType.libraryUpdate:
        return Icons.book;
      case CustomerNotificationType.promotionalOffer:
        return Icons.local_offer;
      case CustomerNotificationType.paymentReminder:
        return Icons.payment;
      case CustomerNotificationType.systemUpdate:
        return Icons.info;
    }
  }

  String _getNotificationTypeLabel(CustomerNotificationType type) {
    switch (type) {
      case CustomerNotificationType.orderConfirmed:
        return 'ORDER CONFIRMED';
      case CustomerNotificationType.orderShipped:
        return 'ORDER SHIPPED';
      case CustomerNotificationType.orderDelivered:
        return 'ORDER DELIVERED';
      case CustomerNotificationType.orderCancelled:
        return 'ORDER CANCELLED';
      case CustomerNotificationType.orderRefunded:
        return 'ORDER REFUNDED';
      case CustomerNotificationType.newBookAvailable:
        return 'NEW BOOK';
      case CustomerNotificationType.libraryUpdate:
        return 'LIBRARY UPDATE';
      case CustomerNotificationType.promotionalOffer:
        return 'SPECIAL OFFER';
      case CustomerNotificationType.paymentReminder:
        return 'PAYMENT REMINDER';
      case CustomerNotificationType.systemUpdate:
        return 'SYSTEM UPDATE';
    }
  }

  String _getActionButtonText(CustomerNotificationType type) {
    switch (type) {
      case CustomerNotificationType.orderConfirmed:
      case CustomerNotificationType.orderShipped:
      case CustomerNotificationType.orderDelivered:
      case CustomerNotificationType.orderCancelled:
      case CustomerNotificationType.orderRefunded:
        return 'View Order';
      case CustomerNotificationType.newBookAvailable:
        return 'View Book';
      case CustomerNotificationType.libraryUpdate:
        return 'Open Library';
      case CustomerNotificationType.promotionalOffer:
        return 'View Offer';
      case CustomerNotificationType.paymentReminder:
        return 'Make Payment';
      case CustomerNotificationType.systemUpdate:
        return 'Learn More';
    }
  }

  void _handleAction(BuildContext context) {
    // Here you would handle navigation based on the actionUrl
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action: ${notification.actionUrl}'),
        backgroundColor: Color(notification.colorValue),
      ),
    );
  }
}
