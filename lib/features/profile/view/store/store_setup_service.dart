import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

/// Service class for handling Firebase operations related to store setup
class StoreSetupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload image to Firebase Storage
  Future<String?> uploadImage({
    required File imageFile,
    required String path,
  }) async {
    try {
      // Get file extension from the original file
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

  /// Create store document and update user role in a batch operation
  Future<void> createStoreWithUserUpdate({
    required Map<String, dynamic> storeData,
    required String userId,
  }) async {
    final batch = _firestore.batch();

    // Reference to store document
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

    // Add store creation to batch
    batch.set(storeRef, storeData);

    // Use update() instead of set() to preserve existing user data
    batch.update(userRef, userUpdateData);

    // Execute batch operation
    await batch.commit();
  }

  /// Check if store name is available (unique)
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

  /// Check if a user has completed store setup
  Future<bool> hasCompletedStoreSetup(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;

      // Only check store setup for users who are trying to be store owners
      // Don't interfere with customers
      final roles = userData['roles'] as List?;
      final isStoreUser = roles?.contains('store') == true;

      if (!isStoreUser)
        return false; // Not a store user, so no store setup needed

      // Check multiple conditions for proper store setup
      return userData['storeSetupCompleted'] == true &&
          userData['storeId'] != null &&
          userData['storeId'].toString().isNotEmpty;
    } catch (e) {
      debugPrint('Error checking store setup status: $e');
      return false;
    }
  }

  /// Check if user is a store owner (has store role)
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

  /// Check if user is a customer (has customer role or no store role)
  Future<bool> isCustomerUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final roles = userData['roles'] as List?;

      // Customer if explicitly has customer role OR doesn't have store role
      return roles?.contains('customer') == true ||
          roles?.contains('store') != true;
    } catch (e) {
      debugPrint('Error checking if user is customer: $e');
      return false;
    }
  }

  /// Get store setup status details (only for store users)
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

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Safely upgrade a user to store owner (preserves existing roles)
  Future<void> upgradeUserToStoreOwner(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      // Add store role while preserving existing roles
      await userRef.update({
        'roles': FieldValue.arrayUnion(['store']),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error upgrading user to store owner: $e');
      rethrow;
    }
  }

  /// Check what type of user this is (for routing decisions)
  Future<String> getUserType(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return 'unknown';

      final userData = userDoc.data()!;
      final roles = userData['roles'] as List?;

      if (roles?.contains('admin') == true) return 'admin';
      if (roles?.contains('store') == true) {
        // Check if store setup is complete
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
