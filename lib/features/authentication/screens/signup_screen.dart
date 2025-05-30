import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/signup_viewmodel.dart';

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
  final _storeNameController = TextEditingController();
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
    // Add listener to format phone number input
    _phoneController.addListener(() {
      final text = _phoneController.text;
      if (text.isNotEmpty) {
        // Remove any non-digit characters first
        var cleaned = text.replaceAll(RegExp(r'[^\d]'), '');
        // Remove leading + or country code if present
        if (cleaned.startsWith('+')) cleaned = cleaned.substring(1);
        if (cleaned.startsWith(_selectedCountry.phoneCode)) {
          cleaned = cleaned.substring(_selectedCountry.phoneCode.length);
        }
        // Format the number as XXX XXX XXXX
        if (cleaned != text) {
          final formatted = cleaned.replaceAllMapped(
            RegExp(r'(\d{3})(\d{3})(\d{4})'),
            (Match m) => '${m[1]} ${m[2]} ${m[3]}',
          );
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
    _storeNameController.dispose();
    super.dispose();
  }

  Future<void> _signUp(SignupViewModel viewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await viewModel.signUp(
          context: context,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber:
              "+${_selectedCountry.phoneCode}${_phoneController.text.trim()}",
          selectedRole: widget.initialRole,
          storeName:
              widget.initialRole == 'store'
                  ? _storeNameController.text.trim()
                  : null,
        );
      } catch (e) {
        if (mounted) {
          String errorMessage = 'An error occurred';

          if (e.toString().contains('[firebase_auth/')) {
            final code = e.toString().split('[firebase_auth/')[1].split(']')[0];
            errorMessage = viewModel.getFirebaseAuthErrorMessage(code);
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
                      if (widget.initialRole == 'store') ...[
                        TextFormField(
                          controller: _storeNameController,
                          decoration: InputDecoration(
                            hintText: 'Store Name',
                            prefixIcon: const Icon(
                              Icons.store_outlined,
                              color: Color(0xFF666666),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            hintStyle: const TextStyle(
                              color: Color(0xFF666666),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your store name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
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
                          hintText: '7XX XXX XXXX',
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
                          // Remove any spaces or special characters
                          final cleanPhone = value.replaceAll(
                            RegExp(r'[\s\-\(\)]'),
                            '',
                          );
                          if (cleanPhone.length < 10) {
                            return 'Phone number is too short';
                          }
                          if (!cleanPhone.startsWith('7')) {
                            return 'Phone number should start with 7';
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
