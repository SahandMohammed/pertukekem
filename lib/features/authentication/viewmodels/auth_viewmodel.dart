import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _firebaseUser;
  UserModel? _user;
  bool _isLoading = false;
  String? _verificationId;
  int? _resendToken;

  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isPhoneVerified => _user?.isPhoneVerified ?? false;

  AuthViewModel() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _firebaseUser = firebaseUser;
    if (firebaseUser != null) {
      // Fetch user data from Firestore
      await _fetchUserData();
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

      // Create user with email and password
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
          phoneNumber: phoneNumber,
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
          if (!userData.isPhoneVerified) {
            throw FirebaseAuthException(
              code: 'requires-verification',
              message:
                  'Phone verification required. Please complete your phone verification.',
            );
          }

          // If verified, update last login timestamp
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

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error during sign out: $e');
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
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout');
          _verificationId = verificationId;
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
        });

        // Fetch updated user data
        await _fetchUserData();
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

  // End of class
}
