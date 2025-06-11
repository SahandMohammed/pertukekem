import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/interfaces/state_clearable.dart';
import '../../authentication/models/user_model.dart';
import '../../authentication/viewmodels/auth_viewmodel.dart';
import '../models/address_model.dart';

class ProfileViewModel extends ChangeNotifier implements StateClearable {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  AuthViewModel? _authViewModel;
  bool _isLoading = false;
  String? _error;
  List<AddressModel> _addresses = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AddressModel> get addresses => _addresses;

  // Set the AuthViewModel reference
  void setAuthViewModel(AuthViewModel authViewModel) {
    _authViewModel = authViewModel;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
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

  @override
  Future<void> clearState() async {
    debugPrint('🧹 Clearing ProfileViewModel state...');

    // Clear auth reference
    _authViewModel = null;

    // Clear all state
    _addresses.clear();
    _error = null;
    _isLoading = false;

    // Notify listeners
    notifyListeners();

    debugPrint('✅ ProfileViewModel state cleared');
  }
}
