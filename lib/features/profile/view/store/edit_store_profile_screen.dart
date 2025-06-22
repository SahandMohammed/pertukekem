import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../authentication/viewmodel/auth_viewmodel.dart';
import '../../../authentication/model/user_model.dart';
import '../../../dashboards/model/store_model.dart';
import '../../viewmodel/store_profile_viewmodel.dart';

class EditStoreProfileScreen extends StatefulWidget {
  final UserModel userProfile;
  final StoreModel? storeProfile;

  const EditStoreProfileScreen({
    super.key,
    required this.userProfile,
    this.storeProfile,
  });

  @override
  State<EditStoreProfileScreen> createState() => _EditStoreProfileScreenState();
}

class _EditStoreProfileScreenState extends State<EditStoreProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Information Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  // Store Information Controllers
  final _storeNameController = TextEditingController();
  final _storeDescriptionController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  // Social Media Controllers
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _websiteController = TextEditingController();

  // Contact Info Controllers
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();

  bool _hasChanges = false;
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize personal information
    _firstNameController.text = widget.userProfile.firstName;
    _lastNameController.text = widget.userProfile.lastName;
    _phoneController.text =
        widget.userProfile.phoneNumber; // Initialize store information
    _storeNameController.text = widget.storeProfile?.storeName ?? '';
    _storeDescriptionController.text = widget.storeProfile?.description ?? '';
    _selectedCategories = List.from(widget.storeProfile?.categories ?? []);

    // Initialize address if available
    if (widget.storeProfile?.storeAddress != null) {
      final address = widget.storeProfile!.storeAddress!;
      _streetController.text = address['street'] ?? '';
      _cityController.text = address['city'] ?? '';
      _stateController.text = address['state'] ?? '';
      _postalCodeController.text = address['postalCode'] ?? '';
      _countryController.text = address['country'] ?? '';
      _additionalInfoController.text = address['additionalInfo'] ?? '';
    }

    // Initialize social media if available
    if (widget.storeProfile?.socialMedia != null) {
      final socialMedia = widget.storeProfile!.socialMedia!;
      _facebookController.text = socialMedia['facebook'] ?? '';
      _instagramController.text = socialMedia['instagram'] ?? '';
      _twitterController.text = socialMedia['twitter'] ?? '';
      _websiteController.text = socialMedia['website'] ?? '';
    } // Initialize contact info if available
    if (widget.storeProfile?.contactInfo != null &&
        widget.storeProfile!.contactInfo.isNotEmpty) {
      // Find phone and email from contact info maps
      for (var contact in widget.storeProfile!.contactInfo) {
        if (contact['type'] == 'phone') {
          _contactPhoneController.text = contact['value'] ?? '';
        } else if (contact['type'] == 'email') {
          _contactEmailController.text = contact['value'] ?? '';
        }
      }
    }

    // Add listeners to detect changes
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _storeNameController.addListener(_onFieldChanged);
    _storeDescriptionController.addListener(_onFieldChanged);
    _streetController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _stateController.addListener(_onFieldChanged);
    _postalCodeController.addListener(_onFieldChanged);
    _countryController.addListener(_onFieldChanged);
    _additionalInfoController.addListener(_onFieldChanged);
    _facebookController.addListener(_onFieldChanged);
    _instagramController.addListener(_onFieldChanged);
    _twitterController.addListener(_onFieldChanged);
    _websiteController.addListener(_onFieldChanged);
    _contactPhoneController.addListener(_onFieldChanged);
    _contactEmailController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final hasChanges =
        _firstNameController.text.trim() != widget.userProfile.firstName ||
        _lastNameController.text.trim() != widget.userProfile.lastName ||
        _phoneController.text.trim() != widget.userProfile.phoneNumber ||
        _storeNameController.text.trim() !=
            (widget.storeProfile?.storeName ?? '') ||
        _storeDescriptionController.text.trim() !=
            (widget.storeProfile?.description ?? '') ||
        _streetController.text.trim() !=
            (widget.storeProfile?.storeAddress?['street'] ?? '') ||
        _cityController.text.trim() !=
            (widget.storeProfile?.storeAddress?['city'] ?? '') ||
        _stateController.text.trim() !=
            (widget.storeProfile?.storeAddress?['state'] ?? '') ||
        _postalCodeController.text.trim() !=
            (widget.storeProfile?.storeAddress?['postalCode'] ?? '') ||
        _countryController.text.trim() !=
            (widget.storeProfile?.storeAddress?['country'] ?? '') ||
        _additionalInfoController.text.trim() !=
            (widget.storeProfile?.storeAddress?['additionalInfo'] ?? '') ||
        _facebookController.text.trim() !=
            (widget.storeProfile?.socialMedia?['facebook'] ?? '') ||
        _instagramController.text.trim() !=
            (widget.storeProfile?.socialMedia?['instagram'] ?? '') ||
        _twitterController.text.trim() !=
            (widget.storeProfile?.socialMedia?['twitter'] ?? '') ||
        _websiteController.text.trim() !=
            (widget.storeProfile?.socialMedia?['website'] ?? '') ||
        _contactPhoneController.text.trim() != _getContactValue('phone') ||
        _contactEmailController.text.trim() != _getContactValue('email');

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _additionalInfoController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _websiteController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final authViewModel = context.read<AuthViewModel>();
    final profileViewModel = context.read<ProfileViewModel>();
    final userId = authViewModel.user?.userId;

    if (userId == null) {
      _showErrorSnackBar('User not authenticated');
      return;
    }

    try {
      // Update user profile first
      final userSuccess = await profileViewModel.updateUserProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      if (!userSuccess) {
        _showErrorSnackBar(
          profileViewModel.error ?? 'Failed to update user profile',
        );
        return;
      } // Update store profile
      final storeAddress = {
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'postalCode': _postalCodeController.text.trim(),
        'country': _countryController.text.trim(),
        'additionalInfo': _additionalInfoController.text.trim(),
      };

      // Create contact info as list of maps
      final contactInfo = <Map<String, String>>[];
      if (_contactPhoneController.text.trim().isNotEmpty) {
        contactInfo.add({
          'type': 'phone',
          'value': _contactPhoneController.text.trim(),
        });
      }
      if (_contactEmailController.text.trim().isNotEmpty) {
        contactInfo.add({
          'type': 'email',
          'value': _contactEmailController.text.trim(),
        });
      }

      // Create social media map
      final socialMedia = <String, String>{};
      if (_facebookController.text.trim().isNotEmpty) {
        socialMedia['facebook'] = _facebookController.text.trim();
      }
      if (_instagramController.text.trim().isNotEmpty) {
        socialMedia['instagram'] = _instagramController.text.trim();
      }
      if (_twitterController.text.trim().isNotEmpty) {
        socialMedia['twitter'] = _twitterController.text.trim();
      }
      if (_websiteController.text.trim().isNotEmpty) {
        socialMedia['website'] = _websiteController.text.trim();
      }

      final storeSuccess = await profileViewModel.updateStoreProfile(
        storeName: _storeNameController.text.trim(),
        description: _storeDescriptionController.text.trim(),
        storeAddress: storeAddress,
        categories: _selectedCategories,
      );

      if (!mounted) return;

      if (storeSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Store profile updated successfully!'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        _showErrorSnackBar(
          profileViewModel.error ?? 'Failed to update store profile',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error updating profile: ${e.toString()}');
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

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          filled: true,
          fillColor: colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),
          labelStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required bool isVerified,
    required String verificationText,
    required ColorScheme colorScheme,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        color: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isVerified
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isVerified
                          ? Colors.green.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVerified ? Icons.verified_rounded : Icons.warning_rounded,
                    size: 14,
                    color:
                        isVerified
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    verificationText,
                    style: textTheme.labelSmall?.copyWith(
                      color:
                          isVerified
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getContactValue(String type) {
    if (widget.storeProfile?.contactInfo != null) {
      for (var contact in widget.storeProfile!.contactInfo) {
        if (contact['type'] == type) {
          return contact['value'] ?? '';
        }
      }
    }
    return '';
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () async {
                    if (!_hasChanges) {
                      Navigator.of(context).pop();
                      return;
                    }
                    final shouldPop = await _onWillPop();
                    if (shouldPop && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: colorScheme.onSurface,
                    size: 20,
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color:
                          _hasChanges
                              ? colorScheme.primary
                              : colorScheme.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow:
                          _hasChanges
                              ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                    ),
                    child: TextButton(
                      onPressed: _hasChanges ? _saveProfile : null,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            _hasChanges
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save_outlined, size: 16),
                          const SizedBox(width: 4),
                          const Text('Save'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withOpacity(0.05),
                    colorScheme.surface,
                    colorScheme.surface,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Edit Store Profile',
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Update your store and personal information',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Personal Information Section
                          _buildSectionCard(
                            context,
                            title: 'Personal Information',
                            subtitle: 'Your basic profile details',
                            icon: Icons.person_outline_rounded,
                            children: [
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _firstNameController,
                                      label: 'First Name',
                                      hint: 'Enter your first name',
                                      icon: Icons.person_outline,
                                      colorScheme: colorScheme,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'First name is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _lastNameController,
                                      label: 'Last Name',
                                      hint: 'Enter your last name',
                                      icon: Icons.person_outline,
                                      colorScheme: colorScheme,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Last name is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                hint: 'Enter your phone number',
                                icon: Icons.phone_outlined,
                                colorScheme: colorScheme,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Phone number is required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Store Information Section
                          _buildSectionCard(
                            context,
                            title: 'Store Information',
                            subtitle: 'Your store details and description',
                            icon: Icons.store_outlined,
                            children: [
                              const SizedBox(height: 24),
                              _buildModernTextField(
                                controller: _storeNameController,
                                label: 'Store Name',
                                hint: 'Enter your store name',
                                icon: Icons.store,
                                colorScheme: colorScheme,
                                textCapitalization: TextCapitalization.words,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Store name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _storeDescriptionController,
                                label: 'Store Description',
                                hint: 'Describe what you sell',
                                icon: Icons.description_outlined,
                                colorScheme: colorScheme,
                                maxLines: 3,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Store description is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              if (_selectedCategories.isNotEmpty) ...[
                                Text(
                                  'Categories',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      _selectedCategories
                                          .map(
                                            (category) => Chip(
                                              label: Text(category),
                                              backgroundColor:
                                                  colorScheme.primaryContainer,
                                              labelStyle: TextStyle(
                                                color:
                                                    colorScheme
                                                        .onPrimaryContainer,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Store Address Section
                          _buildSectionCard(
                            context,
                            title: 'Store Address',
                            subtitle: 'Your store location details',
                            icon: Icons.location_on_outlined,
                            children: [
                              const SizedBox(height: 24),
                              _buildModernTextField(
                                controller: _streetController,
                                label: 'Street Address',
                                hint: 'Enter street address',
                                icon: Icons.home_outlined,
                                colorScheme: colorScheme,
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _cityController,
                                      label: 'City',
                                      hint: 'Enter city',
                                      icon: Icons.location_city_outlined,
                                      colorScheme: colorScheme,
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _stateController,
                                      label: 'State',
                                      hint: 'Enter state',
                                      icon: Icons.map_outlined,
                                      colorScheme: colorScheme,
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _postalCodeController,
                                      label: 'Postal Code',
                                      hint: 'Enter postal code',
                                      icon: Icons.local_post_office_outlined,
                                      colorScheme: colorScheme,
                                      keyboardType: TextInputType.text,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _countryController,
                                      label: 'Country',
                                      hint: 'Enter country',
                                      icon: Icons.public_outlined,
                                      colorScheme: colorScheme,
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _additionalInfoController,
                                label: 'Additional Info',
                                hint: 'Building number, floor, etc.',
                                icon: Icons.info_outline,
                                colorScheme: colorScheme,
                                textCapitalization: TextCapitalization.words,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Social Media Section
                          _buildSectionCard(
                            context,
                            title: 'Social Media & Contact',
                            subtitle:
                                'Your online presence and contact information',
                            icon: Icons.link_outlined,
                            children: [
                              const SizedBox(height: 24),
                              _buildModernTextField(
                                controller: _facebookController,
                                label: 'Facebook URL',
                                hint: 'https://facebook.com/yourstore',
                                icon: Icons.facebook_outlined,
                                colorScheme: colorScheme,
                                keyboardType: TextInputType.url,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _instagramController,
                                      label: 'Instagram',
                                      hint: '@yourstorename',
                                      icon: Icons.camera_alt_outlined,
                                      colorScheme: colorScheme,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _twitterController,
                                      label: 'Twitter',
                                      hint: '@yourstorename',
                                      icon: Icons.alternate_email,
                                      colorScheme: colorScheme,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _websiteController,
                                label: 'Website URL',
                                hint: 'https://yourstore.com',
                                icon: Icons.language_outlined,
                                colorScheme: colorScheme,
                                keyboardType: TextInputType.url,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _contactPhoneController,
                                      label: 'Contact Phone',
                                      hint: 'Store contact number',
                                      icon: Icons.phone_outlined,
                                      colorScheme: colorScheme,
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _contactEmailController,
                                      label: 'Contact Email',
                                      hint: 'Store contact email',
                                      icon: Icons.email_outlined,
                                      colorScheme: colorScheme,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Account Information Section
                          _buildSectionCard(
                            context,
                            title: 'Account Information',
                            subtitle:
                                'Your account details and verification status',
                            icon: Icons.verified_user_outlined,
                            children: [
                              const SizedBox(height: 24),
                              _buildReadOnlyField(
                                context,
                                label: 'Email Address',
                                value: widget.userProfile.email,
                                icon: Icons.email_outlined,
                                isVerified: widget.userProfile.isEmailVerified,
                                verificationText:
                                    widget.userProfile.isEmailVerified
                                        ? 'Verified'
                                        : 'Not Verified',
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 16),
                              _buildReadOnlyField(
                                context,
                                label: 'Store Status',
                                value:
                                    widget.storeProfile?.isVerified == true
                                        ? 'Verified Store'
                                        : 'Pending Verification',
                                icon: Icons.store_mall_directory_outlined,
                                isVerified:
                                    widget.storeProfile?.isVerified ?? false,
                                verificationText:
                                    widget.storeProfile?.isVerified == true
                                        ? 'Verified'
                                        : 'Pending',
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),

                          // Save Changes Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: ElevatedButton(
                                onPressed: _hasChanges ? _saveProfile : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _hasChanges
                                          ? colorScheme.primary
                                          : colorScheme.surfaceVariant,
                                  foregroundColor:
                                      _hasChanges
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurfaceVariant,
                                  elevation: _hasChanges ? 3 : 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _hasChanges
                                          ? Icons.save
                                          : Icons.check_circle_outline,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _hasChanges
                                          ? 'Save Changes'
                                          : 'No Changes',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
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
