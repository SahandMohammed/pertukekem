import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'verify_phone_screen.dart';

class PhoneVerificationFlowScreen extends StatefulWidget {
  const PhoneVerificationFlowScreen({super.key});

  @override
  State<PhoneVerificationFlowScreen> createState() =>
      _PhoneVerificationFlowScreenState();
}

class _PhoneVerificationFlowScreenState
    extends State<PhoneVerificationFlowScreen> {
  bool _isSendingCode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerPhoneVerification();
    });
  }

  Future<void> _triggerPhoneVerification() async {
    final authViewModel = context.read<AuthViewModel>();

    if (authViewModel.user?.phoneNumber == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone number found. Please contact support.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      await authViewModel.sendPhoneVerification(
        phoneNumber: authViewModel.user!.phoneNumber,
        onCodeSent: (verificationId) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder:
                    (context) => VerifyPhoneScreen(
                      verificationId: verificationId,
                      isLogin: false,
                    ),
              ),
            );
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isSendingCode = false;
            });
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
        setState(() {
          _isSendingCode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending verification code: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
          'Phone Verification',
          style: TextStyle(color: Color(0xFF2C3333)),
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthViewModel>(
          builder: (context, viewModel, _) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.phone_android,
                      size: 80,
                      color: Color(0xFF2C3333),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Verify Phone Number',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3333),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (viewModel.user?.phoneNumber != null) ...[
                      Text(
                        'Sending verification code to:',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.user!.phoneNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2C3333),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                    ],
                    if (_isSendingCode)
                      const Column(
                        children: [
                          CircularProgressIndicator(color: Color(0xFF2C3333)),
                          SizedBox(height: 16),
                          Text(
                            'Sending verification code...',
                            style: TextStyle(color: Color(0xFF666666)),
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
                        onPressed: _triggerPhoneVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3333),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Resend Code',
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
