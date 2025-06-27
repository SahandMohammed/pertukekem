import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    try {
      await _initializeLocalNotifications();

      await _requestPermission();

      await _getAndStoreToken();

      _configureMessageHandlers();

      debugPrint('FCM Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidInitialization = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosInitialization = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidInitialization,
      iOS: iosInitialization,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'pertukekem_notifications',
      'Pertukekem Notifications',
      description: 'Notifications for Pertukekem app',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

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

  Future<void> _getAndStoreToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      if (_fcmToken != null && _auth.currentUser != null) {
        await _storeTokenInFirestore(_fcmToken!);
      } else if (_fcmToken == null) {
        debugPrint('Warning: FCM token is null after getToken() call');
      }

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

  Future<String?> refreshToken() async {
    try {
      debugPrint('Forcing FCM token refresh...');
      await _messaging.deleteToken();
      _fcmToken = await _messaging.getToken();
      debugPrint('New FCM Token after refresh: $_fcmToken');

      if (_fcmToken != null && _auth.currentUser != null) {
        await _storeTokenInFirestore(_fcmToken!);
      }

      return _fcmToken;
    } catch (e) {
      debugPrint('Error refreshing FCM token: $e');
      return null;
    }
  }

  Future<void> _storeTokenInFirestore(String token) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final deviceId = _getDeviceId();
      final deviceInfo = {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(currentUser.uid).set({
        'fcmTokens': {deviceId: deviceInfo},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('FCM token stored in Firestore');
    } catch (e) {
      debugPrint('Error storing FCM token: $e');
    }
  }

  String _getDeviceId() {
    final platform = Platform.isIOS ? 'ios' : 'android';
    return '${platform}_device';
  }

  void _configureMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped (background): ${message.messageId}');
      _handleNotificationTap(message);
    });

    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from terminated state: ${message.messageId}');
        _handleNotificationTap(message);
      }
    });
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    debugPrint('Local notification tapped: ${notificationResponse.payload}');

    if (notificationResponse.payload != null) {
      final parts = notificationResponse.payload!.split(':');
      final type = parts.isNotEmpty ? parts[0] : '';
      final id = parts.length > 1 ? parts[1] : null;

      final data = <String, dynamic>{
        'type': type,
        if (id != null) 'orderId': id,
      };

      _handleNotificationTap(RemoteMessage(data: data));
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      _showLocalNotification(message);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final messageId = message.messageId ?? message.hashCode.toString();

      if (_globalShownNotifications.contains(messageId)) {
        debugPrint('Foreground notification already shown: $messageId');
        return;
      }

      _globalShownNotifications.add(messageId);

      if (_globalShownNotifications.length > 50) {
        final oldEntries = _globalShownNotifications.take(
          _globalShownNotifications.length - 50,
        );
        _globalShownNotifications.removeAll(oldEntries);
      }

      final type = message.data['type'] ?? '';
      final orderId = message.data['orderId'];
      final payload = orderId != null ? '$type:$orderId' : type;

      const androidDetails = AndroidNotificationDetails(
        'pertukekem_notifications',
        'Pertukekem Notifications',
        channelDescription: 'Notifications for Pertukekem app',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        messageId.hashCode, // Use consistent ID
        notification.title,
        notification.body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('Local notification shown: ${notification.title}');
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'new_order':
        _navigateToOrders(data);
        break;
      case 'order_update':
        _navigateToOrderDetails(data);
        break;
      case 'low_stock':
        _navigateToListings(data);
        break;
      default:
        _navigateToNotifications();
        break;
    }
  }

  void _navigateToOrders(Map<String, dynamic> data) {
    final context = _getNavigatorContext();
    if (context != null) {
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

  BuildContext? _getNavigatorContext() {
    return null;
  }

  Future<void> subscribeToStoreNotifications(String storeId) async {
    try {
      await _messaging.subscribeToTopic('store_$storeId');
      debugPrint('Subscribed to store notifications: store_$storeId');
    } catch (e) {
      debugPrint('Error subscribing to store notifications: $e');
    }
  }

  Future<void> unsubscribeFromStoreNotifications(String storeId) async {
    try {
      await _messaging.unsubscribeFromTopic('store_$storeId');
      debugPrint('Unsubscribed from store notifications: store_$storeId');
    } catch (e) {
      debugPrint('Error unsubscribing from store notifications: $e');
    }
  }

  Future<void> onUserLogin() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot store FCM token: no user logged in');
        return;
      }

      if (_fcmToken == null) {
        debugPrint('No FCM token available, attempting to get fresh token');
        _fcmToken = await _messaging.getToken();
        debugPrint('Fresh FCM Token: $_fcmToken');
      }

      if (_fcmToken != null) {
        debugPrint('User logged in, storing FCM token');
        await _storeTokenInFirestore(_fcmToken!);
      } else {
        debugPrint(
          'Cannot store FCM token: user=${currentUser.uid}, token=$_fcmToken',
        );
      }
    } catch (e) {
      debugPrint('Error storing FCM token on login: $e');
    }
  }

  Future<void> clearTokens() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).set({
          'fcmTokens': {},
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      _fcmToken = null;
      debugPrint('FCM tokens cleared');
    } catch (e) {
      debugPrint('Error clearing FCM tokens: $e');
    }
  }
}

final Set<String> _globalShownNotifications = <String>{};

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');

  await Firebase.initializeApp();

  await _showBackgroundLocalNotification(message);
}

Future<void> _showBackgroundLocalNotification(RemoteMessage message) async {
  try {
    final notification = message.notification;
    if (notification == null) return;

    final messageId = message.messageId ?? message.hashCode.toString();

    if (_globalShownNotifications.contains(messageId)) {
      debugPrint('Background notification already shown: $messageId');
      return;
    }

    _globalShownNotifications.add(messageId);

    if (_globalShownNotifications.length > 50) {
      final oldEntries = _globalShownNotifications.take(
        _globalShownNotifications.length - 50,
      );
      _globalShownNotifications.removeAll(oldEntries);
    }

    final localNotifications = FlutterLocalNotificationsPlugin();

    const androidInitialization = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosInitialization = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidInitialization,
      iOS: iosInitialization,
    );

    await localNotifications.initialize(initializationSettings);

    final type = message.data['type'] ?? '';
    final orderId = message.data['orderId'];
    final payload = orderId != null ? '$type:$orderId' : type;

    const androidDetails = AndroidNotificationDetails(
      'pertukekem_notifications',
      'Pertukekem Notifications',
      channelDescription: 'Notifications for Pertukekem app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await localNotifications.show(
      messageId.hashCode, // Use consistent ID
      notification.title,
      notification.body,
      notificationDetails,
      payload: payload,
    );

    debugPrint('Background local notification shown: ${notification.title}');
  } catch (e) {
    debugPrint('Error showing background local notification: $e');
  }
}
