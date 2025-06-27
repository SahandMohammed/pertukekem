
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMDebugHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> checkCurrentUserFCMTokens() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      print('=== FCM DEBUG FOR USER: ${user.uid} ===');
      print('📧 Email: ${user.email}');

      final currentToken = await _messaging.getToken();
      print('📱 Current FCM Token: $currentToken');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        print('❌ User document does not exist!');
        return;
      }

      final userData = userDoc.data()!;
      print('👤 User Name: ${userData['firstName']} ${userData['lastName']}');
      print('🏪 Store ID: ${userData['storeId']}');
      print('📚 Store Name: ${userData['storeName']}');
      print('🔐 Roles: ${userData['roles']}');

      final fcmTokens = userData['fcmTokens'];
      if (fcmTokens == null) {
        print('❌ No fcmTokens field in user document!');
        await _fixFCMTokenStorage(user.uid, currentToken);
      } else {
        print('✅ FCM Tokens found: ${(fcmTokens as Map).length} tokens');
        for (final entry in (fcmTokens as Map).entries) {
          final deviceId = entry.key;
          final tokenInfo = entry.value;
          print('  📲 Device $deviceId:');
          print('    - Token: ${tokenInfo['token']}');
          print('    - Platform: ${tokenInfo['platform']}');
          print('    - Last Updated: ${tokenInfo['lastUpdated']}');
        }

        bool currentTokenStored = false;
        for (final tokenInfo in (fcmTokens as Map).values) {
          if (tokenInfo['token'] == currentToken) {
            currentTokenStored = true;
            break;
          }
        }

        if (!currentTokenStored && currentToken != null) {
          print('⚠️ Current token not stored, adding it...');
          await _storeFCMToken(user.uid, currentToken);
        }
      }
    } catch (e) {
      print('❌ Error checking FCM tokens: $e');
    }
  }

  static Future<void> _fixFCMTokenStorage(String userId, String? token) async {
    if (token == null) {
      print('❌ No FCM token available to store');
      return;
    }

    try {
      print('🔧 Fixing FCM token storage...');

      final deviceId = 'android_${DateTime.now().millisecondsSinceEpoch}';
      final tokenInfo = {
        'token': token,
        'platform': 'android',
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).set({
        'fcmTokens': {deviceId: tokenInfo},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ FCM token storage fixed and token stored');
    } catch (e) {
      print('❌ Error fixing FCM token storage: $e');
    }
  }

  static Future<void> _storeFCMToken(String userId, String token) async {
    try {
      final deviceId = 'android_${DateTime.now().millisecondsSinceEpoch}';
      final tokenInfo = {
        'token': token,
        'platform': 'android',
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).update({
        'fcmTokens.$deviceId': tokenInfo,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ FCM token stored successfully');
    } catch (e) {
      print('❌ Error storing FCM token: $e');
    }
  }

  static Future<void> testNotificationTrigger() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final storeId = userData?['storeId'];

      if (storeId == null) {
        print('❌ User does not have a store');
        return;
      }

      print('🧪 Creating test notification trigger...');

      await _firestore.collection('pushNotificationTriggers').add({
        'storeId': storeId,
        'type': 'test',
        'title': 'FCM Debug Test',
        'body': 'This is a test notification to debug FCM delivery',
        'data': {'type': 'test', 'debugTime': DateTime.now().toIso8601String()},
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Test notification trigger created');
    } catch (e) {
      print('❌ Error creating test notification trigger: $e');
    }
  }

  static Future<void> checkCloudFunctionLogs() async {
    print('📋 To check Cloud Function logs, run:');
    print('   firebase functions:log --only sendPushNotification');
    print(
      '   OR visit: https://console.firebase.google.com/project/pertukekem-3fbd4/functions/logs',
    );
  }
}
