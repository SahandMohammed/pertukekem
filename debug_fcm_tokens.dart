// Debug script to check FCM token storage issue
// Run this to understand why notifications are failing

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  print('=== FCM TOKEN DEBUG ===');
  
  final firestore = FirebaseFirestore.instance;
  
  // The store ID from our failing notification
  final storeId = 'iJITZHetrieKJffW5ZHNtnwk6ou2';
  
  print('Investigating store ID: $storeId');
  
  try {
    // 1. Check if this store document exists
    print('\n1. Checking store document...');
    final storeDoc = await firestore.collection('stores').doc(storeId).get();
    print('Store document exists: ${storeDoc.exists}');
    
    if (storeDoc.exists) {
      final storeData = storeDoc.data()!;
      print('Store name: ${storeData['storeName']}');
      print('Store owner ID: ${storeData['ownerId']}');
    }
    
    // 2. Find user with this storeId
    print('\n2. Finding user with storeId = $storeId...');
    final userQuery = await firestore
        .collection('users')
        .where('storeId', '==', storeId)
        .get();
    
    print('Users found: ${userQuery.docs.length}');
    
    if (userQuery.docs.isEmpty) {
      print('❌ NO USERS FOUND WITH THIS STORE ID!');
      
      // Check if there's a user with userId = storeId
      print('\n3. Checking if user document exists with ID = $storeId...');
      final userDoc = await firestore.collection('users').doc(storeId).get();
      print('User document exists: ${userDoc.exists}');
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        print('User name: ${userData['firstName']} ${userData['lastName']}');
        print('User storeId: ${userData['storeId']}');
        print('User FCM tokens: ${userData['fcmTokens']}');
        
        if (userData['storeId'] != storeId) {
          print('❌ MISMATCH: User storeId (${userData['storeId']}) != expected ($storeId)');
        }
      }
    } else {
      // Check the found user's FCM tokens
      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();
      
      print('✅ Found user: ${userData['firstName']} ${userData['lastName']}');
      print('User ID: ${userDoc.id}');
      print('User storeId: ${userData['storeId']}');
      
      final fcmTokens = userData['fcmTokens'];
      if (fcmTokens == null) {
        print('❌ NO FCM TOKENS FOUND IN USER DOCUMENT!');
      } else {
        print('✅ FCM tokens found:');
        final tokens = fcmTokens as Map<String, dynamic>;
        print('Number of tokens: ${tokens.length}');
        
        tokens.forEach((deviceId, tokenInfo) {
          print('  Device: $deviceId');
          if (tokenInfo is Map<String, dynamic>) {
            print('    Token: ${tokenInfo['token']?.substring(0, 20)}...');
            print('    Platform: ${tokenInfo['platform']}');
            print('    Last updated: ${tokenInfo['lastUpdated']}');
          }
        });
      }
    }
    
  } catch (e) {
    print('❌ Error during debug: $e');
  }
  
  print('\n=== END DEBUG ===');
}

// Solutions based on findings:
// 1. If no user found with storeId, update user document: storeId = userId
// 2. If no FCM tokens, user needs to login and register FCM token
// 3. If tokens exist but notifications fail, check Cloud Functions logs
