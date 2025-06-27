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
import '../../dashboards/model/store_model.dart';

class ProfileViewModel extends ChangeNotifier implements StateClearable {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  AuthViewModel? _authViewModel;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isRemovingImage = false;
  bool _isUpdatingStore = false;
  bool _isDisposed = false;
  double _uploadProgress = 0.0;
  String? _error;
  String? _storeProfilePicture;
  List<AddressModel> _addresses = [];
  StoreModel? _storeData;

  bool get isLoading => _isLoading;
  bool get isUploadingImage => _isUploadingImage;
  bool get isRemovingImage => _isRemovingImage;
  bool get isUpdatingStore => _isUpdatingStore;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;
  String? get storeProfilePicture => _storeProfilePicture;
  List<AddressModel> get addresses => _addresses;
  StoreModel? get storeData => _storeData;

  void setAuthViewModel(AuthViewModel authViewModel) {
    _authViewModel = authViewModel;
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _safeNotifyListeners();
  }

  void _setUploadingImage(bool uploading) {
    _isUploadingImage = uploading;
    if (!uploading) {
      _uploadProgress = 0.0;
    }
    _safeNotifyListeners();
  }

  void _setUploadProgress(double progress) {
    _uploadProgress = progress;
    _safeNotifyListeners();
  }

  void _setRemovingImage(bool removing) {
    _isRemovingImage = removing;
    _safeNotifyListeners();
  }

  void _setUpdatingStore(bool updating) {
    _isUpdatingStore = updating;
    _safeNotifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    _safeNotifyListeners();
  }

  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }

  Future<void> loadAddresses(UserModel user) async {
    if (_isDisposed) return;

    try {
      _setLoading(true);
      _setError(null);

      _addresses =
          user.addresses
              .map(
                (addressMap) => AddressModel.fromMap(
                  Map<String, dynamic>.from(addressMap as Map),
                ),
              )
              .toList();

      _addresses.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    } catch (e) {
      if (!_isDisposed) {
        _setError('Failed to load addresses: $e');
        debugPrint('Error loading addresses: $e');
      }
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  Future<String?> addAddress(UserModel user, AddressModel address) async {
    try {
      _setLoading(true);
      _setError(null);

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final addressId = _firestore.collection('temp').doc().id;
      final addressWithId = address.copyWith(
        id: addressId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final currentAddresses = List<Map<String, dynamic>>.from(user.addresses);

      if (addressWithId.isDefault) {
        for (int i = 0; i < currentAddresses.length; i++) {
          currentAddresses[i]['isDefault'] = false;
        }
      }

      currentAddresses.add(addressWithId.toMap()); // Update the user document
      await _firestore.collection('users').doc(userId).update({
        'addresses': currentAddresses,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (_authViewModel != null) {
        await _authViewModel!.refreshUserData();
      }

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

  Future<String?> updateAddress(UserModel user, AddressModel address) async {
    try {
      _setLoading(true);
      _setError(null);

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final currentAddresses = List<Map<String, dynamic>>.from(user.addresses);

      final index = currentAddresses.indexWhere(
        (addr) => addr['id'] == address.id,
      );
      if (index == -1) {
        throw Exception('Address not found');
      }

      if (address.isDefault) {
        for (int i = 0; i < currentAddresses.length; i++) {
          if (i != index) {
            currentAddresses[i]['isDefault'] = false;
          }
        }
      }

      final updatedAddress = address.copyWith(updatedAt: DateTime.now());
      currentAddresses[index] =
          updatedAddress.toMap(); // Update the user document
      await _firestore.collection('users').doc(userId).update({
        'addresses': currentAddresses,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (_authViewModel != null) {
        await _authViewModel!.refreshUserData();
      }

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

  Future<String?> deleteAddress(UserModel user, String addressId) async {
    try {
      _setLoading(true);
      _setError(null);

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final currentAddresses = List<Map<String, dynamic>>.from(user.addresses);

      currentAddresses.removeWhere(
        (addr) => addr['id'] == addressId,
      ); // Update the user document
      await _firestore.collection('users').doc(userId).update({
        'addresses': currentAddresses,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (_authViewModel != null) {
        await _authViewModel!.refreshUserData();
      }

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

  Future<String?> setDefaultAddress(UserModel user, String addressId) async {
    try {
      _setLoading(true);
      _setError(null);

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final currentAddresses = List<Map<String, dynamic>>.from(user.addresses);

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

      if (_authViewModel != null) {
        await _authViewModel!.refreshUserData();
      }

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

  AddressModel? getDefaultAddress() {
    try {
      return _addresses.firstWhere((address) => address.isDefault);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  void _sortAddresses() {
    if (_isDisposed) return;

    _addresses.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    Future.microtask(() {
      if (!_isDisposed) {
        _safeNotifyListeners();
      }
    });
  }

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
      } // Create unique filename
      final String fileName =
          'stores/${currentUser.uid}/profilePicture.jpg'; // Changed to stores folder structure

      final Reference ref = _storage.ref().child(fileName); // Set metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': currentUser.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'type':
              'store_logo', // Changed from 'profile_picture' to 'store_logo'
        },
      ); // Upload file with progress tracking
      final UploadTask uploadTask = ref.putFile(imageFile, metadata);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        _setUploadProgress(progress);
      });

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

  Future<String?> updateProfilePicture(File imageFile) async {
    try {
      _setLoading(true);
      _setError(null);

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final String? downloadUrl = await uploadProfilePicture(imageFile);
      if (downloadUrl == null) {
        throw Exception('Failed to upload image');
      } // Update store document in Firestore
      await _firestore.collection('stores').doc(userId).update({
        'logoUrl': downloadUrl, // Changed from 'profilePicture' to 'logoUrl'
        'updatedAt': FieldValue.serverTimestamp(),
      }); // Update local state
      _storeProfilePicture = downloadUrl;
      _safeNotifyListeners(); // Notify UI immediately after state change

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
  } // Remove profile picture

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
      debugPrint(
        '🗑️ [ViewModel] Current profile picture: $_storeProfilePicture',
      );

      final currentProfilePicture =
          _storeProfilePicture; // Remove from stores collection in Firestore
      debugPrint('🗑️ [ViewModel] Updating Firestore...');
      await _firestore.collection('stores').doc(userId).update({
        'logoUrl':
            FieldValue.delete(), // Changed from 'profilePicture' to 'logoUrl'
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('🗑️ [ViewModel] Firestore update completed');

      if (currentProfilePicture != null && currentProfilePicture.isNotEmpty) {
        try {
          debugPrint('🗑️ [ViewModel] Deleting file from Storage...');
          final ref = _storage.refFromURL(currentProfilePicture);
          await ref.delete();
          debugPrint(
            '🗑️ [ViewModel] Profile picture file deleted from Storage',
          );
        } catch (storageError) {
          debugPrint(
            '🗑️ [ViewModel] Error deleting file from Storage: $storageError',
          );
        }
      } // Update local state
      debugPrint('🗑️ [ViewModel] Updating local state...');
      _storeProfilePicture = null;
      _safeNotifyListeners(); // Notify UI immediately after state change

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

  Future<void> fetchStoreProfilePicture() async {
    if (_isDisposed) return;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('User not authenticated');
        return;
      }

      final doc = await _firestore.collection('stores').doc(userId).get();
      if (doc.exists && !_isDisposed) {
        final data = doc.data();
        _storeProfilePicture =
            data?['logoUrl']; // Changed from 'profilePicture' to 'logoUrl'
        _safeNotifyListeners();
        debugPrint('Store profile picture fetched: $_storeProfilePicture');
      }
    } catch (e) {
      if (!_isDisposed) {
        debugPrint('Error fetching store profile picture: $e');
      }
    }
  }

  Future<StoreModel?> fetchStoreData() async {
    if (_isDisposed) return null;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('User not authenticated');
        return null;
      }

      _setLoading(true);
      _setError(null);

      final doc = await _firestore.collection('stores').doc(userId).get();
      if (doc.exists) {
        if (!_isDisposed) {
          _storeData = StoreModel.fromMap(doc.data()!);
          _safeNotifyListeners();
          debugPrint('Store data fetched: ${_storeData?.storeName}');
        }
        return _storeData;
      } else {
        debugPrint('No store found for user: $userId');
        return null;
      }
    } catch (e) {
      if (!_isDisposed) {
        _setError('Failed to fetch store data: $e');
        debugPrint('Error fetching store data: $e');
      }
      return null;
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  Future<bool> updateStoreProfile({
    required String storeName,
    required String description,
    required Map<String, dynamic> storeAddress,
    List<String>? categories,
    Map<String, dynamic>? businessHours,
    Map<String, dynamic>? socialMedia,
    List<Map<String, String>>? contactInfo,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _setError('User not authenticated');
        return false;
      }

      _setUpdatingStore(true);
      _setError(null);

      final updateData = <String, dynamic>{
        'storeName': storeName,
        'description': description,
        'storeAddress': storeAddress,
        'categories': categories ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (businessHours != null) {
        updateData['businessHours'] = businessHours;
      }

      if (socialMedia != null && socialMedia.isNotEmpty) {
        updateData['socialMedia'] = socialMedia;
      }

      if (contactInfo != null) {
        updateData['contactInfo'] = contactInfo;
      } // Update store document
      await _firestore.collection('stores').doc(userId).update(updateData);

      await _firestore.collection('users').doc(userId).update({
        'storeName': storeName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await fetchStoreData();

      if (_authViewModel != null) {
        await _authViewModel!.refreshUserData();
      }

      debugPrint('Store profile updated successfully');
      return true;
    } catch (e) {
      _setError('Failed to update store profile: $e');
      debugPrint('Error updating store profile: $e');
      return false;
    } finally {
      _setUpdatingStore(false);
    }
  }

  Future<bool> updateUserProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _setError('User not authenticated');
        return false;
      }

      _setUpdatingStore(true);
      _setError(null); // Update user document
      await _firestore.collection('users').doc(userId).update({
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('User profile updated successfully');
      return true;
    } catch (e) {
      _setError('Failed to update user profile: $e');
      debugPrint('Error updating user profile: $e');
      return false;
    } finally {
      _setUpdatingStore(false);
    }
  }

  void updateLocalStoreData({
    String? storeName,
    String? description,
    Map<String, dynamic>? storeAddress,
    List<String>? categories,
    List<Map<String, String>>? contactInfo,
    Map<String, dynamic>? businessHours,
    Map<String, dynamic>? socialMedia,
  }) {
    if (_storeData != null) {
      _storeData = _storeData!.copyWith(
        storeName: storeName ?? _storeData!.storeName,
        description: description ?? _storeData!.description,
        storeAddress: storeAddress ?? _storeData!.storeAddress,
        categories: categories ?? _storeData!.categories,
        businessHours: businessHours ?? _storeData!.businessHours,
        socialMedia: socialMedia ?? _storeData!.socialMedia,
        contactInfo: contactInfo ?? _storeData!.contactInfo,
        updatedAt: DateTime.now(),
      );
    } else {
      final userId = _auth.currentUser?.uid ?? '';
      _storeData = StoreModel(
        storeId: '',
        ownerId: userId,
        storeName: storeName ?? '',
        description: description,
        storeAddress: storeAddress,
        contactInfo: contactInfo ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        categories: categories ?? [],
        businessHours: businessHours,
        socialMedia: socialMedia,
      );
    }
    _safeNotifyListeners();
    debugPrint('Local store data updated: \\${_storeData?.storeName}');
  }

  @override
  Future<void> clearState() async {
    debugPrint('🧹 Clearing ProfileViewModel state...');

    _authViewModel = null;

    _addresses.clear();
    _error = null;
    _isLoading = false;
    _isUploadingImage = false;
    _isRemovingImage = false;
    _isUpdatingStore = false;
    _uploadProgress = 0.0;
    _storeProfilePicture = null;
    _storeData = null;

    _isDisposed = true;

    _safeNotifyListeners();

    debugPrint('✅ ProfileViewModel state cleared');
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
