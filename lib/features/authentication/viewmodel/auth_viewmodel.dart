import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/fcm_service.dart';
import '../model/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FCMService _fcmService = FCMService();

  User? _firebaseUser;
  UserModel? _user;
  bool _isLoading = false;
  int? _resendToken;

  // List of state clearable functions that need cleanup
  final List<Function> _stateClearables = [];

  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isPhoneVerified => _user?.isPhoneVerified ?? false;
  bool get isEmailVerified => _user?.isEmailVerified ?? false;

  AuthViewModel() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Register a function that needs to be called during state cleanup
  void registerStateClearable(Function clearStateFunction) {
    _stateClearables.add(clearStateFunction);
  }

  /// Unregister a state clearable function
  void unregisterStateClearable(Function clearStateFunction) {
    _stateClearables.remove(clearStateFunction);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _firebaseUser = firebaseUser;
    if (firebaseUser != null) {
      // Fetch user data from Firestore
      await _fetchUserData();

      // Trigger FCM token storage when user logs in
      await _fcmService.onUserLogin();
    } else {
      _user = null;
    }
    notifyListeners();
  }

  Future<void> _fetchUserData() async {
    if (_firebaseUser == null) return;

    try {
      final doc =
          await _firestore.collection('users').doc(_firebaseUser!.uid).get();
      if (doc.exists) {
        _user = UserModel.fromMap(doc.data()!);
        debugPrint('User data fetched: $_user');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  // Public method to refresh user data
  Future<void> refreshUserData() async {
    await _fetchUserData();
  }

  // Update local user data immediately (for optimistic UI updates)
  void updateLocalUserData({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? storeName,
  }) {
    if (_user != null) {
      _user = _user!.copyWith(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        storeName: storeName,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      debugPrint(
        'Local user data updated: ${_user?.firstName} ${_user?.lastName}',
      );
    }
  }

  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
    required String selectedRole,
    String? storeName,
  }) async {
    UserCredential? userCredential;
    try {
      _isLoading = true;
      notifyListeners();

      // Ensure phone number is in E.164 format
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        formattedPhone = '+$phoneNumber';
      }

      // FIRST: Check if email is already in use
      final existingEmailQuery =
          await _firestore
              .collection('users')
              .where('emailLowercase', isEqualTo: email.toLowerCase())
              .limit(1)
              .get();

      if (existingEmailQuery.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'An account already exists for this email address',
        );
      }

      // SECOND: Check if phone number is already in use by another verified user
      final existingPhoneQuery =
          await _firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: formattedPhone)
              .where('isPhoneVerified', isEqualTo: true)
              .limit(1)
              .get();

      if (existingPhoneQuery.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'phone-number-already-exists',
          message:
              'This phone number is already registered with another account',
        );
      }

      // THIRD: Create user with email and password only after all validations pass
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user document in Firestore
        final userData = UserModel(
          userId: userCredential.user!.uid,
          firstName: firstName,
          lastName: lastName,
          email: email,
          emailLowercase: email.toLowerCase(),
          phoneNumber: formattedPhone,
          roles: [selectedRole],
          storeName: storeName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          createdByApp: 'mobile',
          isEmailVerified: false,
          isPhoneVerified: false,
          isBlocked: false,
          addresses: [],
          favorites: [],
        );
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData.toMap());

        // Send email verification
        await userCredential.user!.sendEmailVerification();

        // Set the firebase user so phone verification can access it
        _firebaseUser = userCredential.user;

        // Return to allow phone verification to be started from signup screen
        return;
      }
    } catch (e) {
      debugPrint('Error during sign up: $e');

      // If user creation failed and we have a user credential, clean up
      if (userCredential != null && userCredential.user != null) {
        try {
          await userCredential.user!.delete();
          debugPrint('Cleaned up created user due to error');
        } catch (cleanupError) {
          debugPrint('Error cleaning up user: $cleanupError');
        }
      }

      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Sign in user
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Fetch user data to check verification status
      if (_firebaseUser != null) {
        final doc =
            await _firestore.collection('users').doc(_firebaseUser!.uid).get();
        if (doc.exists) {
          final userData = UserModel.fromMap(doc.data()!);

          // Check email verification first
          if (!userData.isEmailVerified) {
            throw FirebaseAuthException(
              code: 'requires-email-verification',
              message:
                  'Email verification required. Please verify your email address.',
            );
          }

          // Then check phone verification
          if (!userData.isPhoneVerified) {
            throw FirebaseAuthException(
              code: 'requires-phone-verification',
              message:
                  'Phone verification required. Please complete your phone verification.',
            );
          }

          // If both verified, update last login timestamp
          await _firestore.collection('users').doc(_firebaseUser!.uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
          debugPrint('User logged in: $_firebaseUser');
        }
      }
    } catch (e) {
      debugPrint('Error during login: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      final emailLower = email.toLowerCase().trim();

      // DEBUG: Skip Firestore check temporarily to test Firebase Auth directly
      bool skipFirestoreCheck = true; // Set to true for debugging

      if (!skipFirestoreCheck) {
        // First check if user exists in our Firestore database using emailLowercase
        QuerySnapshot userQuery =
            await _firestore
                .collection('users')
                .where('emailLowercase', isEqualTo: emailLower)
                .limit(1)
                .get();

        // If not found by emailLowercase, try by email field (for backward compatibility)
        if (userQuery.docs.isEmpty) {
          userQuery =
              await _firestore
                  .collection('users')
                  .where('email', isEqualTo: email.trim())
                  .limit(1)
                  .get();
        }

        // If still not found, try case-insensitive search on email field
        if (userQuery.docs.isEmpty) {
          userQuery =
              await _firestore
                  .collection('users')
                  .where('email', isEqualTo: emailLower)
                  .limit(1)
                  .get();
        }

        debugPrint('Searching for user with email: $email');
        debugPrint('Email lowercase: $emailLower');
        debugPrint('Found ${userQuery.docs.length} users');

        if (userQuery.docs.isEmpty) {
          debugPrint('No user found in Firestore for email: $email');
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No account found with this email address',
          );
        }

        debugPrint('User found in Firestore, sending password reset email');
      } else {
        debugPrint(
          'DEBUG: Skipping Firestore check, trying Firebase Auth directly',
        );
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('Password reset email sent to: $email');
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login with phone number - sends OTP
  Future<void> loginWithPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Ensure phone number is in E.164 format
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        formattedPhone = '+$phoneNumber';
      }

      // First check if user exists in our Firestore database with this phone number
      final userQuery =
          await _firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: formattedPhone)
              .where('isPhoneVerified', isEqualTo: true)
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No verified account found with this phone number',
        );
      }

      debugPrint('Initiating phone login for: $formattedPhone');

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('Auto verification completed for login');
          await _loginWithPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint(
            'Phone login verification failed: ${e.code} - ${e.message}',
          );
          String errorMsg;
          switch (e.code) {
            case 'invalid-phone-number':
              errorMsg = 'The provided phone number is invalid.';
              break;
            case 'too-many-requests':
              errorMsg = 'Too many attempts. Please try again later.';
              break;
            case 'operation-not-allowed':
              errorMsg =
                  'Phone authentication is not enabled for this project.';
              break;
            case 'app-not-authorized':
              errorMsg =
                  'App authentication configuration error. Please try again.';
              break;
            default:
              errorMsg = e.message ?? 'An error occurred during verification.';
          }
          onError(errorMsg);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('Login verification code sent');
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout for login');
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      debugPrint('Unexpected error in loginWithPhoneNumber: $e');
      if (e is FirebaseAuthException) {
        rethrow;
      } else {
        onError('An unexpected error occurred. Please try again.');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify OTP for phone login
  Future<void> verifyPhoneLogin(String verificationId, String smsCode) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await _loginWithPhoneCredential(credential);
    } catch (e) {
      debugPrint('Error during phone login verification: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Helper method to sign in with phone credential
  Future<void> _loginWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      // Sign in with phone credential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Update last login timestamp
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({'lastLoginAt': FieldValue.serverTimestamp()});
        debugPrint(
          'User logged in with phone: ${userCredential.user!.phoneNumber}',
        );
      }
    } catch (e) {
      debugPrint('Error during phone credential login: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🔄 Starting comprehensive sign out process...');
      // 1. Clear FCM token and unsubscribe from notifications
      try {
        await _fcmService.clearTokens();
        debugPrint('✅ FCM tokens cleared');
      } catch (e) {
        debugPrint('⚠️ Error clearing FCM tokens: $e');
      }

      // 2. Clear state in all registered ViewModels
      for (final clearFunction in _stateClearables) {
        try {
          await clearFunction();
          debugPrint('✅ ViewModel state cleared');
        } catch (e) {
          debugPrint('⚠️ Error clearing ViewModel state: $e');
        }
      }

      // 3. Clear local state
      _user = null;
      _resendToken = null;

      // 4. Sign out from Firebase Auth (this will trigger _onAuthStateChanged)
      await _auth.signOut();

      debugPrint('✅ Sign out completed successfully');
    } catch (e) {
      debugPrint('❌ Error during sign out: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<UserModel?> get userStream {
    if (_firebaseUser == null) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(_firebaseUser!.uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  Future<void> sendPhoneVerification({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Ensure phone number is in E.164 format
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        formattedPhone = '+$phoneNumber';
      }

      debugPrint('Initiating phone verification for: $formattedPhone');

      // Check if phone number is already in use by another verified user
      // Skip this check if we're in the signup flow (current user exists but not verified)
      final existingUserQuery =
          await _firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: formattedPhone)
              .where('isPhoneVerified', isEqualTo: true)
              .limit(1)
              .get();

      if (existingUserQuery.docs.isNotEmpty) {
        // Check if it's the same user (current user during signup)
        if (_firebaseUser != null) {
          final existingUser = existingUserQuery.docs.first;
          if (existingUser.id != _firebaseUser!.uid) {
            // Phone number belongs to a different user
            onError(
              'This phone number is already registered with another account',
            );
            return;
          }
        } else {
          // No current user, so this phone number is definitely in use
          onError(
            'This phone number is already registered with another account',
          );
          return;
        }
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('Auto verification completed');
          await _verifyWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Phone verification failed: ${e.code} - ${e.message}');
          String errorMsg;
          switch (e.code) {
            case 'invalid-phone-number':
              errorMsg = 'The provided phone number is invalid.';
              break;
            case 'too-many-requests':
              errorMsg = 'Too many attempts. Please try again later.';
              break;
            case 'operation-not-allowed':
              errorMsg =
                  'Phone authentication is not enabled for this project.';
              break;
            case 'app-not-authorized':
              errorMsg =
                  'App authentication configuration error. Please try again.';
              debugPrint(
                'Firebase Authentication configuration issue. Please check SHA-1 and SHA-256 keys in Firebase Console',
              );
              break;
            default:
              if (e.message?.contains(
                    'Invalid app info in play_integrity_token',
                  ) ??
                  false) {
                errorMsg =
                    'App authentication configuration error. Please try again.';
                debugPrint(
                  'Firebase Authentication configuration issue. Please check SHA-1 and SHA-256 keys in Firebase Console',
                );
              } else {
                errorMsg =
                    e.message ?? 'An error occurred during verification.';
              }
          }
          onError(errorMsg);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('Verification code sent');
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout');
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      debugPrint('Unexpected error in sendPhoneVerification: $e');
      onError('An unexpected error occurred. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyPhoneNumber(String verificationId, String smsCode) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await _verifyWithCredential(credential);
    } catch (e) {
      debugPrint('Error during phone verification: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _verifyWithCredential(PhoneAuthCredential credential) async {
    try {
      if (_firebaseUser != null) {
        // If user is signed in, link the phone credential
        await _firebaseUser!.linkWithCredential(credential);

        // Get the updated user after linking
        _firebaseUser = _auth.currentUser;
        // Update existing user document with phone verification status
        await _firestore.collection('users').doc(_firebaseUser!.uid).update({
          'isPhoneVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
          'phoneNumber': _firebaseUser!.phoneNumber ?? '',
        }); // Fetch updated user data
        await _fetchUserData();

        // Trigger FCM token storage after phone verification
        await _fcmService.onUserLogin();
      } else {
        throw FirebaseAuthException(
          code: 'operation-not-allowed',
          message: 'Cannot verify phone number without being signed in first.',
        );
      }
    } catch (e) {
      debugPrint('Error during phone verification: $e');
      rethrow;
    }
  }

  /// Update phone number for existing user (for profile changes)
  Future<void> updatePhoneNumber(String verificationId, String smsCode) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      if (_firebaseUser != null) {
        // Update the phone number using updatePhoneNumber instead of linking
        await _firebaseUser!.updatePhoneNumber(credential);

        // Get the updated user after phone update
        _firebaseUser = _auth.currentUser;

        // Update user document in Firestore with new phone number
        await _firestore.collection('users').doc(_firebaseUser!.uid).update({
          'phoneNumber': _firebaseUser!.phoneNumber ?? '',
          'isPhoneVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Fetch updated user data
        await _fetchUserData();

        debugPrint(
          'Phone number updated successfully: ${_firebaseUser!.phoneNumber}',
        );
      } else {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No authenticated user found.',
        );
      }
    } catch (e) {
      debugPrint('Error updating phone number: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_firebaseUser == null || _firebaseUser!.email == null) {
      throw Exception('No authenticated user');
    }
    try {
      _isLoading = true;
      notifyListeners();
      // Re-authenticate user
      final cred = EmailAuthProvider.credential(
        email: _firebaseUser!.email!,
        password: currentPassword,
      );
      await _firebaseUser!.reauthenticateWithCredential(cred);
      // Update password
      await _firebaseUser!.updatePassword(newPassword);
    } catch (e) {
      debugPrint('Error changing password: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update email verification status in Firestore
  Future<void> updateEmailVerificationStatus(bool isVerified) async {
    if (_firebaseUser == null) return;

    try {
      await _firestore.collection('users').doc(_firebaseUser!.uid).update({
        'isEmailVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local user data
      if (_user != null) {
        _user = _user!.copyWith(
          isEmailVerified: isVerified,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      debugPrint('Email verification status updated: $isVerified');
    } catch (e) {
      debugPrint('Error updating email verification status: $e');
      rethrow;
    }
  }

  // Update phone verification status in Firestore
  Future<void> updatePhoneVerificationStatus(bool isVerified) async {
    if (_firebaseUser == null) return;

    try {
      await _firestore.collection('users').doc(_firebaseUser!.uid).update({
        'isPhoneVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local user data
      if (_user != null) {
        _user = _user!.copyWith(
          isPhoneVerified: isVerified,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      debugPrint('Phone verification status updated: $isVerified');
    } catch (e) {
      debugPrint('Error updating phone verification status: $e');
      rethrow;
    }
  }

  // End of class
}
