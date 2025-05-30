import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../authentication/viewmodels/auth_viewmodel.dart';
import '../models/store_model.dart';

class StoreViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  StoreModel? _store;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  StoreModel? get store => _store;
  String? get error => _error;

  // Create a new store in Firestore
  Future<void> createStore({
    required String storeName,
    String? description,
    String? address,
    List<Map<String, String>>? contactInfo,
    String? logoUrl,
    List<String>? categories,
    BuildContext? context,
  }) async {
    if (_auth.currentUser == null) {
      _error = 'No authenticated user found';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners(); // Use the user's auth UID as the store document ID
      final userId = _auth.currentUser!.uid;
      final storeRef = _firestore.collection('stores').doc(userId);

      final now = DateTime.now();

      // Create store model
      final newStore = StoreModel(
        storeId: userId, // Use the user's auth UID as the store ID
        ownerId: userId,
        storeName: storeName,
        description: description,
        address: address,
        contactInfo: contactInfo ?? [],
        createdAt: now,
        updatedAt: now,
        logoUrl: logoUrl,
        categories: categories ?? [],
      );

      // Save to Firestore
      await storeRef.set(newStore.toMap());

      // Update the user document with the storeId
      await _firestore.collection('users').doc(userId).update({
        'storeId': userId, // Store ID is now the same as user ID
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh the AuthViewModel to get updated user data
      if (context != null) {
        final authViewModel = Provider.of<AuthViewModel>(
          context,
          listen: false,
        );
        await authViewModel.refreshUserData();
      }

      _store = newStore;
    } catch (e) {
      _error = 'Failed to create store: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch store details by storeId
  Future<void> fetchStoreById(String storeId) async {
    if (storeId.isEmpty) {
      _error = 'Store ID is empty';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final storeDoc = await _firestore.collection('stores').doc(storeId).get();

      if (storeDoc.exists) {
        _store = StoreModel.fromMap(storeDoc.data()!);
      } else {
        _error = 'Store not found';
      }
    } catch (e) {
      _error = 'Failed to fetch store: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get store for current user
  Future<void> fetchCurrentUserStore() async {
    if (_auth.currentUser == null) {
      _error = 'No authenticated user found';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get user document to find storeId
      final userDoc =
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .get();

      if (!userDoc.exists) {
        _error = 'User document not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final userData = userDoc.data();
      final storeId = userData?['storeId'];

      if (storeId == null) {
        _error = 'User does not have a store';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch the store document
      await fetchStoreById(storeId);
    } catch (e) {
      _error = 'Failed to fetch user\'s store: $e';
      debugPrint(_error);
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update store information
  Future<void> updateStore(StoreModel updatedStore) async {
    if (_auth.currentUser == null) {
      _error = 'No authenticated user found';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Update the updatedAt field
      final storeToUpdate = updatedStore.copyWith(updatedAt: DateTime.now());

      // Update in Firestore
      await _firestore
          .collection('stores')
          .doc(updatedStore.storeId)
          .update(storeToUpdate.toMap());

      _store = storeToUpdate;
    } catch (e) {
      _error = 'Failed to update store: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
