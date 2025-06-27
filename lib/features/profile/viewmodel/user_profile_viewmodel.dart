import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../authentication/model/user_model.dart';
import '../services/user_profile_service.dart';

class UserProfileViewModel extends ChangeNotifier {
  final UserProfileService _userProfileService = UserProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  UserModel? _userProfile;
  bool _isLoading = false;
  String? _error;
  bool _isUpdating = false;
  bool _isUploadingImage = false;
  String? _tempProfilePictureUrl;

  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isUpdating => _isUpdating;
  bool get isUploadingImage => _isUploadingImage;
  String? get tempProfilePictureUrl => _tempProfilePictureUrl;

  Future<void> loadUserProfile(String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final profile = await _userProfileService.getUserProfile(userId);
      _userProfile = profile;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? profilePicture,
  }) async {
    _setUpdating(true);
    _setError(null);

    try {
      final updates = <String, dynamic>{
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phoneNumber': phoneNumber.trim(),
      };

      if (profilePicture != null) {
        updates['profilePicture'] = profilePicture;
      }

      await _userProfileService.updateUserProfile(userId, updates);

      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          phoneNumber: phoneNumber.trim(),
          profilePicture: profilePicture ?? _userProfile!.profilePicture,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  Stream<UserModel?> getUserProfileStream(String userId) {
    return _userProfileService.getUserProfileStream(userId);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setUpdating(bool updating) {
    _isUpdating = updating;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> pickAndUploadProfilePicture(String userId) async {
    try {
      _setUploadingImage(true);
      _setError(null);

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile == null) {
        return false; // User cancelled
      }

      final imageFile = File(pickedFile.path);

      final downloadUrl = await _userProfileService.uploadProfilePicture(
        userId,
        imageFile,
      );

      await _userProfileService.updateProfilePicture(userId, downloadUrl);

      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(
          profilePicture: downloadUrl,
          updatedAt: DateTime.now(),
        );
      }

      _tempProfilePictureUrl = downloadUrl;
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to upload profile picture: $e');
      return false;
    } finally {
      _setUploadingImage(false);
    }
  }

  Future<bool> takeAndUploadProfilePicture(String userId) async {
    try {
      _setUploadingImage(true);
      _setError(null);

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile == null) {
        return false; // User cancelled
      }

      final imageFile = File(pickedFile.path);

      final downloadUrl = await _userProfileService.uploadProfilePicture(
        userId,
        imageFile,
      );

      await _userProfileService.updateProfilePicture(userId, downloadUrl);

      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(
          profilePicture: downloadUrl,
          updatedAt: DateTime.now(),
        );
      }

      _tempProfilePictureUrl = downloadUrl;
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to upload profile picture: $e');
      return false;
    } finally {
      _setUploadingImage(false);
    }
  }

  Future<bool> removeProfilePicture(String userId) async {
    try {
      _setUploadingImage(true);
      _setError(null);

      final currentImageUrl = _userProfile?.profilePicture;

      await _userProfileService.deleteProfilePicture(userId, currentImageUrl);

      await _userProfileService.updateProfilePicture(userId, null);

      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(
          profilePicture: null,
          updatedAt: DateTime.now(),
        );
      }

      _tempProfilePictureUrl = null;
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to remove profile picture: $e');
      return false;
    } finally {
      _setUploadingImage(false);
    }
  }

  void _setUploadingImage(bool uploading) {
    _isUploadingImage = uploading;
    notifyListeners();
  }
}
