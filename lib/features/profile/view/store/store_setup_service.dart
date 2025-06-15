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

    // Reference to user document
    final userRef = _firestore.collection('users').doc(userId);

    // Add store creation to batch
    batch.set(storeRef, storeData);

    // Add user update to batch
    batch.update(userRef, {
      'storeId': userId,
      'role': 'storeOwner',
      'updatedAt': FieldValue.serverTimestamp(),
    });

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

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
