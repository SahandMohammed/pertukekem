import 'package:flutter/foundation.dart';
import '../../authentication/model/user_model.dart';
import '../services/user_profile_service.dart';

class UserProfileViewModel extends ChangeNotifier {
  final UserProfileService _userProfileService = UserProfileService();

  UserModel? _userProfile;
  bool _isLoading = false;
  String? _error;
  bool _isUpdating = false;

  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isUpdating => _isUpdating;

  /// Load user profile
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

  /// Update user profile
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

      // Update local model
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

  /// Stream user profile changes
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
}
