import 'package:firebase_auth/firebase_auth.dart';
import '../service/customer_notification_service.dart';

class NotificationTestHelper {
  static final CustomerNotificationService _notificationService =
      CustomerNotificationService();

  /// Create sample notifications for testing
  static Future<void> createSampleNotifications() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final customerId = currentUser.uid;

    try {
      // Order confirmation notification
      await _notificationService.createOrderConfirmationNotification(
        customerId: customerId,
        orderId: 'test_order_001',
        orderNumber: 'PK001234',
        totalAmount: 45.99,
        storeName: 'BookHaven Store',
      );

      // Order shipped notification
      await _notificationService.createOrderShippedNotification(
        customerId: customerId,
        orderId: 'test_order_002',
        orderNumber: 'PK001235',
        storeName: 'Literary Corner',
        trackingNumber: 'TN123456789',
      );

      // New book notification
      await _notificationService.createNewBookNotification(
        customerId: customerId,
        bookTitle: 'The Art of Programming',
        author: 'John Smith',
        storeId: 'store_001',
        storeName: 'TechBooks Pro',
      );

      // Promotional notification
      await _notificationService.createPromotionalNotification(
        customerId: customerId,
        title: '🎉 Special Offer - 30% Off!',
        message:
            'Get 30% off on all programming books this weekend. Limited time offer!',
        metadata: {
          'discountPercent': 30,
          'validUntil': '2025-06-20',
          'category': 'programming',
        },
      );

      // System notification
      await _notificationService.createSystemNotification(
        customerId: customerId,
        title: 'App Update Available',
        message:
            'A new version of Pertukekem is available with bug fixes and new features.',
        metadata: {
          'version': '1.2.0',
          'features': [
            'Enhanced reading experience',
            'Better search',
            'Bug fixes',
          ],
        },
      );

      print('Sample notifications created successfully!');
    } catch (e) {
      print('Error creating sample notifications: $e');
    }
  }

  /// Create an order delivered notification
  static Future<void> createOrderDeliveredNotification() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await _notificationService.createOrderDeliveredNotification(
        customerId: currentUser.uid,
        orderId: 'test_order_003',
        orderNumber: 'PK001236',
        storeName: 'Classic Books',
      );

      print('Order delivered notification created!');
    } catch (e) {
      print('Error creating order delivered notification: $e');
    }
  }

  /// Create a promotional notification
  static Future<void> createPromotionalOffer() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await _notificationService.createPromotionalNotification(
        customerId: currentUser.uid,
        title: '📚 New Arrivals Alert!',
        message:
            'Check out the latest arrivals in our Science Fiction collection. Over 50 new titles added!',
        metadata: {'category': 'science_fiction', 'newTitlesCount': 50},
      );

      print('Promotional notification created!');
    } catch (e) {
      print('Error creating promotional notification: $e');
    }
  }
}
