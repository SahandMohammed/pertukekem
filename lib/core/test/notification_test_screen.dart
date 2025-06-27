import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pertukekem/core/services/fcm_service.dart';
import 'package:pertukekem/features/notifications/service/unified_notification_service.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final _fcmService = FCMService();
  final _notificationService = UnifiedNotificationService();
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
                      : const Text(
                        'Test New Order Notification',
                        style: TextStyle(color: Colors.white),
                      ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _testOrderUpdateNotification,
              child: const Text(
                'Test Order Update Notification',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _testDirectPushNotification,
              child: const Text(
                'Test Direct Push Notification',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: _isLoading ? null : _checkUserData,
              child: const Text('Check User FCM Data'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : _fixFCMTokenStorage,
              child: const Text('Fix FCM Token Storage'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : _triggerFCMTokenStorage,
              child: const Text('Trigger FCM Token Storage'),
            ),
            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: _isLoading ? null : _refreshFCMToken,
              child: const Text('Force Refresh FCM Token'),
            ),
            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: _isLoading ? null : _checkCloudFunctionLogs,
              child: const Text('View Debug Instructions'),
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

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final storeId = userData?['storeId'];

      if (storeId == null) {
        throw Exception('User does not have a store');
      }

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

      final currentToken = _fcmService.fcmToken;

      setState(() {
        _status = '''
User Data Check:
- User ID: ${user.uid}
- Email: ${user.email}
- Store ID: ${storeId ?? 'Not set'}
- FCM Tokens: ${fcmTokens != null ? '${(fcmTokens as Map).length} tokens' : 'No tokens'}
- Current FCM Token: ${currentToken ?? 'Not available'}

FCM Tokens in Firestore:
${fcmTokens != null ? _formatFCMTokens(fcmTokens as Map) : 'None stored'}
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

  String _formatFCMTokens(Map tokens) {
    if (tokens.isEmpty) return 'No tokens stored';

    String result = '';
    tokens.forEach((deviceId, tokenInfo) {
      result += '- Device: $deviceId\n';
      result += '  Token: ${tokenInfo['token']}\n';
      result += '  Platform: ${tokenInfo['platform']}\n';
      result += '  Updated: ${tokenInfo['lastUpdated']}\n\n';
    });
    return result;
  }

  Future<void> _fixFCMTokenStorage() async {
    setState(() {
      _isLoading = true;
      _status = 'Fixing FCM token storage...';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final currentToken = _fcmService.fcmToken;
      if (currentToken == null) {
        throw Exception('No FCM token available');
      }

      final deviceId = 'android_${DateTime.now().millisecondsSinceEpoch}';
      final tokenInfo = {
        'token': currentToken,
        'platform': 'android',
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).set({
        'fcmTokens': {deviceId: tokenInfo},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _status =
            'FCM token storage fixed! Current token has been stored in Firestore.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error fixing FCM token storage: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerFCMTokenStorage() async {
    setState(() {
      _isLoading = true;
      _status = 'Triggering FCM token storage...';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _fcmService.onUserLogin();

      setState(() {
        _status = 'FCM token storage triggered successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error triggering FCM token storage: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkCloudFunctionLogs() async {
    setState(() {
      _status = '''
Debug Instructions:

1. Check Firebase Functions logs:
   - Go to Firebase Console > Functions > Logs
   - OR run: firebase functions:log --only sendPushNotification

2. Check if tokens are being stored:
   - Use "Check User FCM Data" button above
   - If no tokens, use "Fix FCM Token Storage"

3. Test notification flow:
   - Create a test notification trigger
   - Check logs for "No FCM tokens found" errors
   - Verify Cloud Function execution

4. Common issues:
   - fcmTokens field missing in user document
   - Invalid or expired FCM tokens
   - Cloud Function permissions
   - Network connectivity on device

Current logged in user should have FCM tokens stored to receive notifications.
        ''';
    });
  }

  Future<void> _refreshFCMToken() async {
    setState(() {
      _isLoading = true;
      _status = 'Force refreshing FCM token...';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final newToken = await _fcmService.refreshToken();

      setState(() {
        _status =
            newToken != null
                ? 'FCM token refreshed successfully!\nNew token: ${newToken.substring(0, 20)}...'
                : 'Failed to refresh FCM token';
      });
    } catch (e) {
      setState(() {
        _status = 'Error refreshing FCM token: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
