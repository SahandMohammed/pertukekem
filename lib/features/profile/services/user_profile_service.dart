import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../authentication/model/user_model.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Fetch user profile data from Firestore
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final docSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        // Add the userId to the data since it's not stored in the document
        data['userId'] = userId;
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  /// Update user profile data in Firestore
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Listen to user profile changes
  Stream<UserModel?> getUserProfileStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        data['userId'] = userId;
        return UserModel.fromMap(data);
      }
      return null;
    });
  }

  /// Get user's saved books count
  Future<int> getUserSavedBooksCount(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final favorites = List<dynamic>.from(data['favorites'] ?? []);
        return favorites.length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get user's purchase count from orders
  Future<int> getUserPurchaseCount(String userId) async {
    try {
      final ordersQuery =
          await _firestore
              .collection('orders')
              .where('buyerId', isEqualTo: userId)
              .where('status', isEqualTo: 'completed')
              .get();

      return ordersQuery.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Upload profile picture to Firebase Storage
  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('users/$userId/profile_picture.jpg');

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploaded_by': userId,
            'upload_time': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Delete profile picture from Firebase Storage
  Future<void> deleteProfilePicture(
    String userId,
    String? currentImageUrl,
  ) async {
    try {
      if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
        // Delete from Firebase Storage
        final ref = _storage.refFromURL(currentImageUrl);
        await ref.delete();
      }
    } catch (e) {
      // Don't throw error if file doesn't exist
      print('Warning: Could not delete profile picture: $e');
    }
  }

  /// Update user profile picture
  Future<void> updateProfilePicture(String userId, String? imageUrl) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null) {
        updates['profilePicture'] = imageUrl;
      } else {
        updates['profilePicture'] = FieldValue.delete();
      }

      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update profile picture: $e');
    }
  }
}
