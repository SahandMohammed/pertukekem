import 'package:flutter/material.dart';
import '../utils/notification_test_helper.dart';

class NotificationDebugScreen extends StatelessWidget {
  const NotificationDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Testing'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Notification Testing',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use these buttons to create sample notifications for testing the notification system.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 32),

            _buildTestButton(
              context,
              title: 'Create Sample Notifications',
              subtitle: 'Creates 5 different types of notifications',
              icon: Icons.notifications_active,
              color: Colors.blue,
              onPressed: () => _createSampleNotifications(context),
            ),

            const SizedBox(height: 16),

            _buildTestButton(
              context,
              title: 'Order Delivered',
              subtitle: 'Create an order delivered notification',
              icon: Icons.check_circle,
              color: Colors.green,
              onPressed: () => _createOrderDeliveredNotification(context),
            ),

            const SizedBox(height: 16),

            _buildTestButton(
              context,
              title: 'Promotional Offer',
              subtitle: 'Create a promotional notification',
              icon: Icons.local_offer,
              color: Colors.orange,
              onPressed: () => _createPromotionalNotification(context),
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.yellow.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.yellow.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'These are test notifications. In production, notifications will be triggered by real events like order updates, new books, etc.',
                      style: TextStyle(
                        color: Colors.yellow.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createSampleNotifications(BuildContext context) async {
    _showLoading(context, 'Creating sample notifications...');

    try {
      await NotificationTestHelper.createSampleNotifications();
      Navigator.of(context).pop(); // Close loading
      _showSuccess(context, 'Sample notifications created successfully!');
    } catch (e) {
      Navigator.of(context).pop(); // Close loading
      _showError(context, 'Failed to create notifications: $e');
    }
  }

  void _createOrderDeliveredNotification(BuildContext context) async {
    _showLoading(context, 'Creating order delivered notification...');

    try {
      await NotificationTestHelper.createOrderDeliveredNotification();
      Navigator.of(context).pop(); // Close loading
      _showSuccess(context, 'Order delivered notification created!');
    } catch (e) {
      Navigator.of(context).pop(); // Close loading
      _showError(context, 'Failed to create notification: $e');
    }
  }

  void _createPromotionalNotification(BuildContext context) async {
    _showLoading(context, 'Creating promotional notification...');

    try {
      await NotificationTestHelper.createPromotionalOffer();
      Navigator.of(context).pop(); // Close loading
      _showSuccess(context, 'Promotional notification created!');
    } catch (e) {
      Navigator.of(context).pop(); // Close loading
      _showError(context, 'Failed to create notification: $e');
    }
  }

  void _showLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(child: Text(message)),
              ],
            ),
          ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
