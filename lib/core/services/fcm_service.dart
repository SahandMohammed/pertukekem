import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      await _requestPermission();

      // Get FCM token
      await _getAndStoreToken();

      // Configure message handlers
      _configureMessageHandlers();

      debugPrint('FCM Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional notification permission');
    } else {
      debugPrint('User declined or has not accepted notification permission');
    }
  }

  /// Get FCM token and store it in Firestore
  Future<void> _getAndStoreToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      if (_fcmToken != null && _auth.currentUser != null) {
        await _storeTokenInFirestore(_fcmToken!);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        if (_auth.currentUser != null) {
          _storeTokenInFirestore(newToken);
        }
      });
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Store FCM token in Firestore user document
  Future<void> _storeTokenInFirestore(String token) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final deviceInfo = {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Use set with merge to ensure fcmTokens field is created if it doesn't exist
      await _firestore.collection('users').doc(currentUser.uid).set({
        'fcmTokens.${_getDeviceId()}': deviceInfo,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('FCM token stored in Firestore');
    } catch (e) {
      debugPrint('Error storing FCM token: $e');
    }
  }

  /// Get a unique device identifier
  String _getDeviceId() {
    // Create a simple device identifier based on platform and timestamp
    final platform = Platform.isIOS ? 'ios' : 'android';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return '${platform}_$timestamp';
  }

  /// Configure message handlers for different app states
  void _configureMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle notification taps when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped (background): ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from a terminated state via notification
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from terminated state: ${message.messageId}');
        _handleNotificationTap(message);
      }
    });
  }

  /// Handle foreground messages (show in-app notification)
  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      // Show in-app notification or banner
      _showInAppNotification(message);
    }
  }

  /// Handle notification tap actions
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'new_order':
        // Navigate to orders screen
        _navigateToOrders(data);
        break;
      case 'order_update':
        // Navigate to specific order
        _navigateToOrderDetails(data);
        break;
      case 'low_stock':
        // Navigate to listings
        _navigateToListings(data);
        break;
      default:
        // Navigate to notifications screen
        _navigateToNotifications();
        break;
    }
  }

  /// Show in-app notification banner
  void _showInAppNotification(RemoteMessage message) {
    final context = _getNavigatorContext();
    if (context == null) return;

    // Create custom in-app notification
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _getNotificationIcon(message.data['type']),
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.notification?.title ?? 'New Notification',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (message.notification?.body != null)
                            Text(
                              message.notification!.body!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => overlayEntry.remove(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    // Auto remove after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      try {
        overlayEntry.remove();
      } catch (e) {
        // Entry might already be removed
      }
    });

    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  /// Get appropriate icon for notification type
  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'new_order':
        return Icons.shopping_cart;
      case 'order_update':
        return Icons.update;
      case 'low_stock':
        return Icons.inventory;
      case 'review':
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }

  /// Navigation methods
  void _navigateToOrders(Map<String, dynamic> data) {
    final context = _getNavigatorContext();
    if (context != null) {
      // Navigate to orders tab or screen
      // Implementation depends on your navigation structure
      Navigator.of(context).pushNamed('/orders');
    }
  }

  void _navigateToOrderDetails(Map<String, dynamic> data) {
    final context = _getNavigatorContext();
    final orderId = data['orderId'];
    if (context != null && orderId != null) {
      Navigator.of(context).pushNamed('/order-details', arguments: orderId);
    }
  }

  void _navigateToListings(Map<String, dynamic> data) {
    final context = _getNavigatorContext();
    if (context != null) {
      Navigator.of(context).pushNamed('/listings');
    }
  }

  void _navigateToNotifications() {
    final context = _getNavigatorContext();
    if (context != null) {
      Navigator.of(context).pushNamed('/notifications');
    }
  }

  /// Get current navigator context
  BuildContext? _getNavigatorContext() {
    // This would need to be implemented based on your app structure
    // You might need to store a global navigator key
    return null;
  }

  /// Subscribe to topic for store owners
  Future<void> subscribeToStoreNotifications(String storeId) async {
    try {
      await _messaging.subscribeToTopic('store_$storeId');
      debugPrint('Subscribed to store notifications: store_$storeId');
    } catch (e) {
      debugPrint('Error subscribing to store notifications: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromStoreNotifications(String storeId) async {
    try {
      await _messaging.unsubscribeFromTopic('store_$storeId');
      debugPrint('Unsubscribed from store notifications: store_$storeId');
    } catch (e) {
      debugPrint('Error unsubscribing from store notifications: $e');
    }
  }

  /// Clean up tokens when user signs out
  Future<void> clearTokens() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'fcmTokens': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      _fcmToken = null;
      debugPrint('FCM tokens cleared');
    } catch (e) {
      debugPrint('Error clearing FCM tokens: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');

  // You can perform background tasks here like updating local database
  // or showing local notifications
}
