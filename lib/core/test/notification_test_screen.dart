import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pertukekem/core/services/fcm_service.dart';
import 'package:pertukekem/features/dashboards/store/services/notification_service.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final _fcmService = FCMService();
  final _notificationService = NotificationService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _status = 'Ready to test notifications';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Notification Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'FCM Token: ${_fcmService.fcmToken ?? 'Not available'}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'User: ${_auth.currentUser?.email ?? 'Not logged in'}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isLoading ? null : _testNewOrderNotification,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Test New Order Notification'),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _isLoading ? null : _testOrderUpdateNotification,
              child: const Text('Test Order Update Notification'),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _isLoading ? null : _testDirectPushNotification,
              child: const Text('Test Direct Push Notification'),
            ),
            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: _isLoading ? null : _checkUserData,
              child: const Text('Check User FCM Data'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testNewOrderNotification() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing new order notification...';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get user's store ID
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final storeId = userData?['storeId'];

      if (storeId == null) {
        throw Exception('User does not have a store');
      }

      await _notificationService.createNewOrderNotification(
        storeId: storeId,
        orderId: 'test_order_${DateTime.now().millisecondsSinceEpoch}',
        orderNumber: 'TEST123',
        totalAmount: 29.99,
        customerName: 'Test Customer',
      );

      setState(() {
        _status = 'New order notification created successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testOrderUpdateNotification() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing order update notification...';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get user's store ID
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final storeId = userData?['storeId'];

      if (storeId == null) {
        throw Exception('User does not have a store');
      }

      await _notificationService.createOrderUpdateNotification(
        storeId: storeId,
        orderId: 'test_order_update_${DateTime.now().millisecondsSinceEpoch}',
        orderNumber: 'UPD456',
        newStatus: 'shipped',
        customerName: 'Test Customer',
      );

      setState(() {
        _status = 'Order update notification created successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testDirectPushNotification() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing direct push notification...';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get user's store ID
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final storeId = userData?['storeId'];

      if (storeId == null) {
        throw Exception('User does not have a store');
      }

      // Create a direct push notification trigger
      await _firestore.collection('pushNotificationTriggers').add({
        'storeId': storeId,
        'type': 'test',
        'title': 'Test Notification',
        'body': 'This is a test push notification from the app!',
        'data': {
          'type': 'test',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _status = 'Direct push notification trigger created successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkUserData() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking user FCM data...';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      final storeId = userData?['storeId'];
      final fcmTokens = userData?['fcmTokens'];

      setState(() {
        _status = '''
User Data Check:
- Store ID: ${storeId ?? 'Not set'}
- FCM Tokens: ${fcmTokens != null ? '${(fcmTokens as Map).length} tokens' : 'No tokens'}
- Current FCM Token: ${_fcmService.fcmToken ?? 'Not available'}
        ''';
      });
    } catch (e) {
      setState(() {
        _status = 'Error checking user data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
