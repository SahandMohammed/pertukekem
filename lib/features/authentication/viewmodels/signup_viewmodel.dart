import 'package:flutter/material.dart';
import 'auth_viewmodel.dart';

class SignupViewModel extends ChangeNotifier {
  final AuthViewModel _authViewModel;
  bool _isLoading = false;

  SignupViewModel(this._authViewModel);

  bool get isLoading => _isLoading;

  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(email);
  }

  String getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists for this email';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'weak-password':
        return 'Please enter a stronger password';
      case 'invalid-phone-number':
        return 'The provided phone number is invalid';
      default:
        return 'An error occurred. Please try again';
    }
  }

  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
    required String selectedRole,
    required BuildContext context,
    String? storeName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // First create the account with email/password
      await _authViewModel.signUp(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        selectedRole: selectedRole,
        storeName: storeName,
      );

      // After successful signup, immediately start phone verification
      if (context.mounted) {
        // Add a small delay to ensure Firebase Auth state is updated
        await Future.delayed(const Duration(milliseconds: 500));
        await _authViewModel.sendPhoneVerification(
          phoneNumber: phoneNumber,
          onCodeSent: (String verificationId) {
            // Navigate to OTP screen
            Navigator.of(
              context,
            ).pushNamed('/verify-phone', arguments: verificationId);
          },
          onError: (String error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error during signup process: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPhoneVerification(
    String phoneNumber,
    BuildContext context,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authViewModel.sendPhoneVerification(
        phoneNumber: phoneNumber,
        onCodeSent: (String verificationId) {
          // Navigate to OTP screen
          Navigator.of(
            context,
          ).pushNamed('/verify-phone', arguments: verificationId);
        },
        onError: (String error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
