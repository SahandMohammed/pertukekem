import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../viewmodel/signup_viewmodel.dart';

class SignUpScreen extends StatefulWidget {
  final String initialRole;

  const SignUpScreen({super.key, required this.initialRole});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  Country _selectedCountry = Country(
    phoneCode: "964",
    countryCode: "IQ",
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: "Iraq",
    example: "0770 123 4567",
    displayName: "Iraq [+964]",
    displayNameNoCountryCode: "Iraq",
    e164Key: "",
  );

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      final text = _phoneController.text;
      if (text.isNotEmpty) {
        var cleaned = text.replaceAll(RegExp(r'[^\d]'), '');

        if (cleaned.startsWith(_selectedCountry.phoneCode)) {
          cleaned = cleaned.substring(_selectedCountry.phoneCode.length);
        }

        String formatted = '';
        if (cleaned.length <= 10) {
          if (cleaned.length >= 1) {
            formatted += cleaned.substring(
              0,
              cleaned.length >= 3 ? 3 : cleaned.length,
            );
            if (cleaned.length > 3) {
              formatted +=
                  ' ${cleaned.substring(3, cleaned.length >= 6 ? 6 : cleaned.length)}';
              if (cleaned.length > 6) {
                formatted +=
                    ' ${cleaned.substring(6, cleaned.length >= 10 ? 10 : cleaned.length)}';
              }
            }
          }
        } else if (cleaned.length == 11 && cleaned.startsWith('0')) {
          formatted += cleaned.substring(0, 4); // 0770
          if (cleaned.length > 4) {
            formatted += ' ${cleaned.substring(4, 7)}'; // 000
            if (cleaned.length > 7) {
              formatted += ' ${cleaned.substring(7, 11)}'; // 0000
            }
          }
        } else {
          formatted = cleaned;
        }

        if (formatted != text) {
          _phoneController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<bool> _checkEmailExists(String email) async {
    final firestore = FirebaseFirestore.instance;
    final query =
        await firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .get();
    return query.docs.isNotEmpty;
  }

  Future<bool> _checkPhoneExists(String phone) async {
    final firestore = FirebaseFirestore.instance;
    final query =
        await firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: phone)
            .get();
    return query.docs.isNotEmpty;
  }

  Future<void> _signUp(SignupViewModel viewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!viewModel.isValidEmail(_emailController.text.trim())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enter a valid email address'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
      final phone = _phoneController.text.trim().replaceAll(' ', '');
      if (phone.length < 9) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enter a valid phone number'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
      final email = _emailController.text.trim();
      final fullPhone = "+${_selectedCountry.phoneCode}${phone}";
      if (await _checkEmailExists(email)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'An account already exists for this email address',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
      if (await _checkPhoneExists(fullPhone)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'This phone number is already registered with another account',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
      try {
        await viewModel.signUp(
          context: context,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: email,
          password: _passwordController.text,
          phoneNumber: fullPhone,
          selectedRole: widget.initialRole,
        );
      } catch (e) {
        if (mounted) {
          String errorMessage = 'An error occurred';
          if (e.toString().contains('email-already-in-use')) {
            errorMessage = 'An account already exists for this email address';
          } else if (e.toString().contains('phone-number-already-exists') ||
              e.toString().contains('credential-already-in-use') ||
              e.toString().contains('phone number is already in use')) {
            errorMessage =
                'This phone number is already registered with another account';
          } else if (e.toString().contains('[firebase_auth/')) {
            final code = e.toString().split('[firebase_auth/')[1].split(']')[0];
            errorMessage = viewModel.getFirebaseAuthErrorMessage(code);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SignupViewModel(context.read<AuthViewModel>()),
      child: Consumer<SignupViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3333)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 40.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.initialRole == 'store'
                            ? 'Create Store Account'
                            : 'Create Account',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.initialRole == 'store'
                            ? 'Set up your store profile'
                            : 'Fill in your details to get started',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 48),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          hintText: 'First Name',
                          prefixIcon: const Icon(
                            Icons.person_outline,
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          hintText: 'Last Name',
                          prefixIcon: const Icon(
                            Icons.person_outline,
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          prefixIcon: const Icon(
                            Icons.email_outlined,
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
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!viewModel.isValidEmail(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: 'Password',
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
                          hintStyle: const TextStyle(color: Color(0xFF666666)),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          hintText: '770 000 0000',
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: TextButton(
                              onPressed: () {
                                showCountryPicker(
                                  context: context,
                                  countryListTheme: CountryListThemeData(
                                    borderRadius: BorderRadius.circular(12),
                                    inputDecoration: InputDecoration(
                                      hintText: 'Search country',
                                      filled: true,
                                      fillColor: const Color(0xFFF5F5F5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  onSelect: (Country country) {
                                    setState(() {
                                      _selectedCountry = country;
                                    });
                                  },
                                );
                              },
                              child: Text(
                                "+${_selectedCountry.phoneCode}",
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 16,
                                ),
                              ),
                            ),
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          final cleanPhone = value.replaceAll(
                            RegExp(r'[\s\-\(\)]'),
                            '',
                          );
                          if (cleanPhone.length < 10) {
                            return 'Phone number is too short';
                          }
                          if (!cleanPhone.startsWith('7') &&
                              !cleanPhone.startsWith('07')) {
                            return 'Phone number should start with 7 or 07';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed:
                            viewModel.isLoading
                                ? null
                                : () => _signUp(viewModel),
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
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed:
                            viewModel.isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF666666),
                        ),
                        child: const Text(
                          'Already have an account? Sign In',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
