import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../authentication/model/user_model.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final docSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        data['userId'] = userId;
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

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

  Future<void> deleteProfilePicture(
    String userId,
    String? currentImageUrl,
  ) async {
    try {
      if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
        final ref = _storage.refFromURL(currentImageUrl);
        await ref.delete();
      }
    } catch (e) {
      print('Warning: Could not delete profile picture: $e');
    }
  }

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
