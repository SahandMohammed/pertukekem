import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/interfaces/state_clearable.dart';
import '../../authentication/model/user_model.dart';
import '../../authentication/viewmodel/auth_viewmodel.dart';
import '../model/address_model.dart';

class ProfileViewModel extends ChangeNotifier implements StateClearable {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  AuthViewModel? _authViewModel;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isRemovingImage = false;
  double _uploadProgress = 0.0;
  String? _error;
  String? _storeProfilePicture;
  List<AddressModel> _addresses = [];

  bool get isLoading => _isLoading;
  bool get isUploadingImage => _isUploadingImage;
  bool get isRemovingImage => _isRemovingImage;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;
  String? get storeProfilePicture => _storeProfilePicture;
  List<AddressModel> get addresses => _addresses;

  // Set the AuthViewModel reference
  void setAuthViewModel(AuthViewModel authViewModel) {
    _authViewModel = authViewModel;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    Future.microtask(() => notifyListeners());
  }

  void _setUploadingImage(bool uploading) {
    _isUploadingImage = uploading;
    if (!uploading) {
      _uploadProgress = 0.0;
    }
    Future.microtask(() => notifyListeners());
  }

  void _setUploadProgress(double progress) {
    _uploadProgress = progress;
    Future.microtask(() => notifyListeners());
  }

  void _setRemovingImage(bool removing) {
    _isRemovingImage = removing;
    Future.microtask(() => notifyListeners());
  }

  void _setError(String? error) {
    _error = error;
    Future.microtask(() => notifyListeners());
  }

  void clearError() {
    _error = null;
    Future.microtask(() => notifyListeners());
  }

  // Load addresses from user document
  Future<void> loadAddresses(UserModel user) async {
    try {
      _setLoading(true);
      _setError(null);

      // Convert the addresses list to AddressModel objects
      _addresses =
          user.addresses
              .map(
                (addressMap) => AddressModel.fromMap(
                  Map<String, dynamic>.from(addressMap as Map),
                ),
              )
              .toList();

      // Sort addresses with default address first
      _addresses.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    } catch (e) {
      _setError('Failed to load addresses: $e');
      debugPrint('Error loading addresses: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add a new address
  Future<String?> addAddress(UserModel user, AddressModel address) async {
    try {
      _setLoading(true);
      _setError(null);

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Generate a unique ID for the address
      final addressId = _firestore.collection('temp').doc().id;
      final addressWithId = address.copyWith(
        id: addressId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Get current addresses
      final currentAddresses = List<Map<String, dynamic>>.from(user.addresses);

      // If this is set as default, make sure no other address is default
      if (addressWithId.isDefault) {
        for (int i = 0; i < currentAddresses.length; i++) {
          currentAddresses[i]['isDefault'] = false;
        }
      }

      // Add the new address
      currentAddresses.add(addressWithId.toMap()); // Update the user document
      await _firestore.collection('users').doc(userId).update({
        'addresses': currentAddresses,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh AuthViewModel to get updated user data
      if (_authViewModel != null) {
        await _authViewModel!.refreshUserData();
      }

      // Update local list
      _addresses.add(addressWithId);
      _sortAddresses();

      return null; // Success
    } catch (e) {
      final errorMessage = 'Failed to add address: $e';
      _setError(errorMessage);
      debugPrint('Error adding address: $e');
      return errorMessage;
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing address
  Future<String?> updateAddress(UserModel user, AddressModel address) async {
    try {
      _setLoading(true);
      _setError(null);

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get current addresses
      final currentAddresses = List<Map<String, dynamic>>.from(user.addresses);

      // Find and update the address
      final index = currentAddresses.indexWhere(
        (addr) => addr['id'] == address.id,
      );
      if (index == -1) {
        throw Exception('Address not found');
      }

      // If this is set as default, make sure no other address is default
      if (address.isDefault) {
        for (int i = 0; i < currentAddresses.length; i++) {
          if (i != index) {
            currentAddresses[i]['isDefault'] = false;
          }
        }
      }

      // Update the address with new timestamp
      final updatedAddress = address.copyWith(updatedAt: DateTime.now());
      currentAddresses[index] =
          updatedAddress.toMap(); // Update the user document
      await _firestore.collection('users').doc(userId).update({
        'addresses': currentAddresses,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh AuthViewModel to get updated user data
      if (_authViewModel != null) {
        await _authViewModel!.refreshUserData();
      }

      // Update local list
      final localIndex = _addresses.indexWhere((addr) => addr.id == address.id);
      if (localIndex != -1) {
        _addresses[localIndex] = updatedAddress;
        _sortAddresses();
      }

      return null; // Success
    } catch (e) {
      final errorMessage = 'Failed to update address: $e';
      _setError(errorMessage);
      debugPrint('Error updating address: $e');
      return errorMessage;
    } finally {
      _setLoading(false);
    }
  }

  // Delete an address
  Future<String?> deleteAddress(UserModel user, String addressId) async {
    try {
      _setLoading(true);
      _setError(null);

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get current addresses
      final currentAddresses = List<Map<String, dynamic>>.from(user.addresses);

      // Remove the address
      currentAddresses.removeWhere(
        (addr) => addr['id'] == addressId,
      ); // Update the user document
      await _firestore.collection('users').doc(userId).update({
        'addresses': currentAddresses,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh AuthViewModel to get updated user data
      if (_authViewModel != null) {
        await _authViewModel!.refreshUserData();
      }

      // Update local list
      _addresses.removeWhere((addr) => addr.id == addressId);

      return null; // Success
    } catch (e) {
      final errorMessage = 'Failed to delete address: $e';
      _setError(errorMessage);
      debugPrint('Error deleting address: $e');
      return errorMessage;
    } finally {
      _setLoading(false);
    }
  }

  // Set an address as default
  Future<String?> setDefaultAddress(UserModel user, String addressId) async {
    try {
      _setLoading(true);
      _setError(null);

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get current addresses
      final currentAddresses = List<Map<String, dynamic>>.from(user.addresses);

      // Update all addresses to remove default status, then set the selected one as default
      for (int i = 0; i < currentAddresses.length; i++) {
        currentAddresses[i]['isDefault'] =
            currentAddresses[i]['id'] == addressId;
        if (currentAddresses[i]['id'] == addressId) {
          currentAddresses[i]['updatedAt'] =
              DateTime.now().millisecondsSinceEpoch;
        }
      } // Update the user document
      await _firestore.collection('users').doc(userId).update({
        'addresses': currentAddresses,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh AuthViewModel to get updated user data
      if (_authViewModel != null) {
        await _authViewModel!.refreshUserData();
      }

      // Update local list
      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(
          isDefault: _addresses[i].id == addressId,
          updatedAt:
              _addresses[i].id == addressId
                  ? DateTime.now()
                  : _addresses[i].updatedAt,
        );
      }
      _sortAddresses();

      return null; // Success
    } catch (e) {
      final errorMessage = 'Failed to set default address: $e';
      _setError(errorMessage);
      debugPrint('Error setting default address: $e');
      return errorMessage;
    } finally {
      _setLoading(false);
    }
  }

  // Get the default address
  AddressModel? getDefaultAddress() {
    try {
      return _addresses.firstWhere((address) => address.isDefault);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  // Helper method to sort addresses
  void _sortAddresses() {
    _addresses.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    Future.microtask(() => notifyListeners());
  }

  // Pick image from camera or gallery
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      _setError('Error picking image: $e');
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Upload profile picture to Firebase Storage
  Future<String?> uploadProfilePicture(File imageFile) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('User not authenticated');
      return null;
    }

    try {
      _setUploadingImage(true);
      _setError(null);

      if (!await imageFile.exists()) {
        throw Exception('Selected image file not found');
      }

      // Create unique filename
      final String fileName =
          'profile_pictures/${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Create reference to Firebase Storage
      final Reference ref = _storage.ref().child(fileName);

      // Set metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': currentUser.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': 'profile_picture',
        },
      ); // Upload file with progress tracking
      final UploadTask uploadTask = ref.putFile(imageFile, metadata);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        _setUploadProgress(progress);
      });

      // Wait for upload to complete
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      debugPrint(
        'Profile picture upload successful. Download URL: $downloadUrl',
      );
      return downloadUrl;
    } catch (e) {
      final errorMessage = 'Failed to upload profile picture: $e';
      _setError(errorMessage);
      debugPrint('Error uploading profile picture: $e');
      return null;
    } finally {
      _setUploadingImage(false);
    }
  }

  // Update user's profile picture in Firestore
  Future<String?> updateProfilePicture(File imageFile) async {
    try {
      _setLoading(true);
      _setError(null);

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Upload image to Firebase Storage
      final String? downloadUrl = await uploadProfilePicture(imageFile);
      if (downloadUrl == null) {
        throw Exception('Failed to upload image');
      } // Update store document in Firestore
      await _firestore.collection('stores').doc(userId).update({
        'profilePicture': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      _storeProfilePicture = downloadUrl;

      // Refresh AuthViewModel to get updated user data
      if (_authViewModel != null) {
        await _authViewModel!.refreshUserData();
      }

      return null; // Success
    } catch (e) {
      final errorMessage = 'Failed to update profile picture: $e';
      _setError(errorMessage);
      debugPrint('Error updating profile picture: $e');
      return errorMessage;
    } finally {
      _setLoading(false);
    }
  }  // Remove profile picture
  Future<String?> removeProfilePicture() async {
    try {
      debugPrint('🗑️ [ViewModel] Starting removeProfilePicture...');
      _setRemovingImage(true);
      _setError(null);

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🗑️ [ViewModel] User ID: $userId');
      debugPrint('🗑️ [ViewModel] Current profile picture: $_storeProfilePicture');

      // Get current profile picture URL before deleting
      final currentProfilePicture = _storeProfilePicture;

      // Remove from stores collection in Firestore
      debugPrint('🗑️ [ViewModel] Updating Firestore...');
      await _firestore.collection('stores').doc(userId).update({
        'profilePicture': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('🗑️ [ViewModel] Firestore update completed');

      // Delete the actual file from Firebase Storage if it exists
      if (currentProfilePicture != null && currentProfilePicture.isNotEmpty) {
        try {
          debugPrint('🗑️ [ViewModel] Deleting file from Storage...');
          final ref = _storage.refFromURL(currentProfilePicture);
          await ref.delete();
          debugPrint('🗑️ [ViewModel] Profile picture file deleted from Storage');
        } catch (storageError) {
          // Log but don't fail the operation if file doesn't exist
          debugPrint('🗑️ [ViewModel] Error deleting file from Storage: $storageError');
        }
      }

      // Update local state
      debugPrint('🗑️ [ViewModel] Updating local state...');
      _storeProfilePicture = null;

      // Refresh AuthViewModel to get updated user data
      if (_authViewModel != null) {
        debugPrint('🗑️ [ViewModel] Refreshing AuthViewModel...');
        await _authViewModel!.refreshUserData();
        debugPrint('🗑️ [ViewModel] AuthViewModel refresh completed');
      }

      debugPrint('🗑️ [ViewModel] removeProfilePicture completed successfully');
      return null; // Success
    } catch (e) {
      final errorMessage = 'Failed to remove profile picture: $e';
      _setError(errorMessage);
      debugPrint('Error removing profile picture: $e');
      return errorMessage;
    } finally {
      _setRemovingImage(false);
    }
  }

  // Fetch store profile picture from Firestore
  Future<void> fetchStoreProfilePicture() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('User not authenticated');
        return;
      }

      final doc = await _firestore.collection('stores').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        _storeProfilePicture = data?['profilePicture'];
        Future.microtask(() => notifyListeners());
        debugPrint('Store profile picture fetched: $_storeProfilePicture');
      }
    } catch (e) {
      debugPrint('Error fetching store profile picture: $e');
    }
  }

  @override
  Future<void> clearState() async {
    debugPrint('🧹 Clearing ProfileViewModel state...');

    // Clear auth reference
    _authViewModel = null; // Clear all state
    _addresses.clear();
    _error = null;
    _isLoading = false;
    _isUploadingImage = false;
    _isRemovingImage = false;
    _uploadProgress = 0.0;
    _storeProfilePicture = null;

    // Notify listeners
    notifyListeners();

    debugPrint('✅ ProfileViewModel state cleared');
  }
}
