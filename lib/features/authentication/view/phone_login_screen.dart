import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'verify_phone_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No verified account found with this phone number';
      case 'invalid-phone-number':
        return 'Please enter a valid phone number';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled';
      case 'app-not-authorized':
        return 'App authentication configuration error';
      default:
        return 'An error occurred. Please try again';
    }
  }

  Future<void> _sendPhoneOTP() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        await context.read<AuthViewModel>().loginWithPhoneNumber(
          phoneNumber: _phoneController.text.trim(),
          onCodeSent: (verificationId) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => VerifyPhoneScreen(
                        verificationId: verificationId,
                        isLogin:
                            true, // Add this parameter to distinguish login vs signup
                      ),
                ),
              );
            }
          },
          onError: (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
        );
      } catch (e) {
        if (mounted) {
          String errorMessage = 'An error occurred';

          if (e.toString().contains('[firebase_auth/')) {
            final code = e.toString().split('[firebase_auth/')[1].split(']')[0];
            errorMessage = _getFirebaseAuthErrorMessage(code);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  bool _isValidPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    // Check if it has at least 10 digits (minimum for most countries)
    return digits.length >= 10 && digits.length <= 15;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Phone Login',
          style: TextStyle(
            color: Color(0xFF2C3333),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.phone_android,
                  size: 80,
                  color: Color(0xFF2C3333),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sign in with Phone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3333),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Enter your phone number and we\'ll send you a verification code to sign in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: 'Phone Number (e.g., +1234567890)',
                    prefixIcon: const Icon(
                      Icons.phone,
                      color: Color(0xFF666666),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: const TextStyle(color: Color(0xFF666666)),
                  ),
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!_isValidPhoneNumber(value)) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE3F2FD)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF1976D2),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Include your country code (e.g., +1 for US, +60 for Malaysia)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendPhoneOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3333),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Send Verification Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF666666),
                  ),
                  child: const Text(
                    'Back to Email Login',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
