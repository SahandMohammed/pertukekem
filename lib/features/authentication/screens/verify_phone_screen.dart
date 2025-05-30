import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class VerifyPhoneScreen extends StatefulWidget {
  final String verificationId;

  const VerifyPhoneScreen({super.key, required this.verificationId});

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
  Future<void> _verifyOTP(AuthViewModel viewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await viewModel.verifyPhoneNumber(
          widget.verificationId,
          _otpController.text.trim(),
        );
        
        if (mounted) {        // Check if the user is a store owner and needs to complete setup
          if (viewModel.user != null && 
              viewModel.user!.roles.contains('store')) {
            // Navigate to store setup
            Navigator.of(context).pushNamedAndRemoveUntil('/store-setup', (route) => false);
          } else {
            // Default case - navigate to main app
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          }
        }
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
      }
    }
  }

  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-verification-id':
        return 'Invalid verification session';
      case 'code-expired':
        return 'The verification code has expired';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return 'An error occurred. Please try again';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Enter OTP',
          style: TextStyle(color: Color(0xFF2C3333)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthViewModel>(
          builder: (context, viewModel, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Verification Code',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please enter the 6-digit code sent to your phone number.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: 'Enter 6-digit code',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF666666),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        counterText: '',
                        hintStyle: const TextStyle(color: Color(0xFF666666)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the verification code';
                        }
                        if (value.length != 6) {
                          return 'Please enter all 6 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed:
                          viewModel.isLoading
                              ? null
                              : () => _verifyOTP(viewModel),
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
                          viewModel.isLoading
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
                                'Verify Code',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
