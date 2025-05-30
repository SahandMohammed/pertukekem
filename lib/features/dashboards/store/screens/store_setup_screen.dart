import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../authentication/viewmodels/auth_viewmodel.dart';
import '../viewmodels/store_viewmodel.dart';

class StoreSetupScreen extends StatefulWidget {
  const StoreSetupScreen({super.key});

  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Form controllers
  final _storeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Selected categories
  final List<String> _selectedCategories = [];

  // All available categories
  final List<String> _availableCategories = [
    'Chemistry',
    'Biology',
    'Physics',
    'Mathematics',
    'Engineering',
    'Environmental Science',
    'Medical',
    'Agricultural',
    'Industrial',
    'Educational',
    'Research',
    'Laboratory Equipment',
  ];

  int _currentPage = 0;
  bool _isProcessing = false;
  @override
  void initState() {
    super.initState();

    // Pre-fill email and phone using AuthViewModel
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (authViewModel.user != null) {
      _emailController.text = authViewModel.user!.email;
      _phoneController.text = authViewModel.user!.phoneNumber;

      // Pre-fill store name if it exists
      if (authViewModel.user!.storeName != null) {
        _storeNameController.text = authViewModel.user!.storeName!;
      }

      // Check if store already exists
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (authViewModel.user!.storeId != null &&
            authViewModel.user!.storeId!.isNotEmpty) {
          try {
            await Provider.of<StoreViewModel>(
              context,
              listen: false,
            ).fetchStoreById(authViewModel.user!.storeId!);

            // Add this check to ensure the widget is still mounted before navigating
            if (!mounted) return;

            final storeViewModel = Provider.of<StoreViewModel>(
              context,
              listen: false,
            );
            if (storeViewModel.store != null) {
              // Store already exists, navigate to dashboard
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            }
          } catch (e) {
            // Silently handle any error during initialization
            debugPrint('Error checking existing store: $e');
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Handle form submission to create the store
  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Prepare contact info
      final List<Map<String, String>> contactInfo = [];

      if (_emailController.text.isNotEmpty) {
        contactInfo.add({
          'type': 'email',
          'value': _emailController.text.trim(),
        });
      }

      if (_phoneController.text.isNotEmpty) {
        contactInfo.add({
          'type': 'phone',
          'value': _phoneController.text.trim(),
        });
      }

      // Create the store using StoreViewModel
      final storeViewModel = Provider.of<StoreViewModel>(
        context,
        listen: false,
      );

      await storeViewModel.createStore(
        storeName: _storeNameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        contactInfo: contactInfo,
        categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
        context: context,
      );

      if (mounted) {
        if (storeViewModel.error != null) {
          _showErrorSnackBar(storeViewModel.error!);
        } else {
          // Add a small delay to ensure all state updates are processed
          await Future.delayed(const Duration(milliseconds: 300));

          // Navigate to the store dashboard
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to create store: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _nextPage() {
    if (_currentPage == 0 && _storeNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your store name');
      return;
    }

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitForm();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
          'Set Up Your Store',
          style: TextStyle(
            color: Color(0xFF2C3333),
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading:
            _currentPage > 0
                ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3333)),
                  onPressed: _previousPage,
                )
                : null,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentPage + 1) / 3,
                backgroundColor: Colors.grey[200],
                color: const Color(0xFF1B5E20),
              ),
              const SizedBox(height: 8),

              // Page indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Step ${_currentPage + 1} of 3',
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Form pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildBasicInfoPage(),
                    _buildContactInfoPage(),
                    _buildCategoriesPage(),
                  ],
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: _isProcessing ? null : _previousPage,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF666666),
                        ),
                        child: const Text('Previous'),
                      )
                    else
                      const SizedBox.shrink(),

                    ElevatedButton(
                      onPressed: _isProcessing ? null : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isProcessing
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                _currentPage == 2 ? 'Finish' : 'Next',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Page 1: Basic store information
  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3333),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Let\'s start with some basic information about your store.',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 32),

          // Store name field
          _buildFormField(
            controller: _storeNameController,
            label: 'Store Name',
            hint: 'Enter your store name',
            prefixIcon: Icons.store_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your store name';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Store description field
          _buildFormField(
            controller: _descriptionController,
            label: 'Description (Optional)',
            hint: 'Briefly describe your store',
            prefixIcon: Icons.description_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Store address field
          _buildFormField(
            controller: _addressController,
            label: 'Address (Optional)',
            hint: 'Your store\'s physical address',
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // Page 2: Contact information
  Widget _buildContactInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3333),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please provide your contact information so customers can reach you.',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 32),

          // Email field
          _buildFormField(
            controller: _emailController,
            label: 'Email',
            hint: 'Your business email address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email address';
              }
              // Simple email validation
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Phone field
          _buildFormField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Your business phone number',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // Page 3: Store categories
  Widget _buildCategoriesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Store Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3333),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select categories that describe the types of chemicals you sell.',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 24),

          // Categories grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _availableCategories.length,
            itemBuilder: (context, index) {
              final category = _availableCategories[index];
              final isSelected = _selectedCategories.contains(category);

              return _buildCategoryChip(
                category: category,
                isSelected: isSelected,
                onToggle: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCategories.remove(category);
                    } else {
                      _selectedCategories.add(category);
                    }
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Generic form field builder
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, color: const Color(0xFF666666)),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintStyle: const TextStyle(color: Color(0xFF666666)),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // Category selection chip
  Widget _buildCategoryChip({
    required String category,
    required bool isSelected,
    required VoidCallback onToggle,
  }) {
    return Material(
      color: isSelected ? const Color(0xFFA5D6A7) : const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    color:
                        isSelected
                            ? const Color(0xFF1B5E20)
                            : const Color(0xFF666666),
                    fontWeight:
                        isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF1B5E20),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
