import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class StoreSetupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImage({
    required File imageFile,
    required String path,
  }) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final extension =
          fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final fullPath = '$path.$extension';

      final ref = _storage.ref().child(fullPath);
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> createStoreWithUserUpdate({
    required Map<String, dynamic> storeData,
    required String userId,
  }) async {
    final batch = _firestore.batch();

    final storeRef = _firestore.collection('stores').doc(userId);

    final userRef = _firestore
        .collection('users')
        .doc(
          userId,
        ); // Add storeId to users collection "storeId" field (update, don't replace)
    final userUpdateData = {
      'storeId': storeRef.id,
      'roles': FieldValue.arrayUnion([
        'store',
      ]), // Add 'store' role if not present
      'storeSetupCompleted': true, // Explicit flag for completed setup
      'storeSetupCompletedAt':
          FieldValue.serverTimestamp(), // Timestamp of completion
      'updatedAt': FieldValue.serverTimestamp(),
    };

    batch.set(storeRef, storeData);

    batch.update(userRef, userUpdateData);

    await batch.commit();
  }

  Future<bool> isStoreNameAvailable(String storeName) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('stores')
              .where('storeName', isEqualTo: storeName)
              .limit(1)
              .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking store name availability: $e');
      return false;
    }
  }

  Future<bool> hasCompletedStoreSetup(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;

      final roles = userData['roles'] as List?;
      final isStoreUser = roles?.contains('store') == true;

      if (!isStoreUser)
        return false; // Not a store user, so no store setup needed

      return userData['storeSetupCompleted'] == true &&
          userData['storeId'] != null &&
          userData['storeId'].toString().isNotEmpty;
    } catch (e) {
      debugPrint('Error checking store setup status: $e');
      return false;
    }
  }

  Future<bool> isStoreUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final roles = userData['roles'] as List?;
      return roles?.contains('store') == true;
    } catch (e) {
      debugPrint('Error checking if user is store user: $e');
      return false;
    }
  }

  Future<bool> isCustomerUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final roles = userData['roles'] as List?;

      return roles?.contains('customer') == true ||
          roles?.contains('store') != true;
    } catch (e) {
      debugPrint('Error checking if user is customer: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getStoreSetupStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return {
          'isComplete': false,
          'isStoreUser': false,
          'hasStoreId': false,
          'hasStoreRole': false,
          'setupCompletedAt': null,
        };
      }

      final userData = userDoc.data()!;
      final roles = userData['roles'] as List?;
      final hasStoreRole = roles?.contains('store') == true;
      final hasStoreId =
          userData['storeId'] != null &&
          userData['storeId'].toString().isNotEmpty;
      final isComplete = userData['storeSetupCompleted'] == true;

      return {
        'isComplete': hasStoreRole && isComplete && hasStoreId,
        'isStoreUser': hasStoreRole,
        'hasStoreId': hasStoreId,
        'hasStoreRole': hasStoreRole,
        'setupCompletedAt': userData['storeSetupCompletedAt'],
        'storeId': userData['storeId'],
      };
    } catch (e) {
      debugPrint('Error getting store setup status: $e');
      return {
        'isComplete': false,
        'isStoreUser': false,
        'hasStoreId': false,
        'hasStoreRole': false,
        'setupCompletedAt': null,
      };
    }
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  Future<void> upgradeUserToStoreOwner(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await userRef.update({
        'roles': FieldValue.arrayUnion(['store']),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error upgrading user to store owner: $e');
      rethrow;
    }
  }

  Future<String> getUserType(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return 'unknown';

      final userData = userDoc.data()!;
      final roles = userData['roles'] as List?;

      if (roles?.contains('admin') == true) return 'admin';
      if (roles?.contains('store') == true) {
        final storeSetupComplete = await hasCompletedStoreSetup(userId);
        return storeSetupComplete ? 'store_owner' : 'store_incomplete';
      }

      return 'customer'; // Default to customer
    } catch (e) {
      debugPrint('Error getting user type: $e');
      return 'unknown';
    }
  }
}
