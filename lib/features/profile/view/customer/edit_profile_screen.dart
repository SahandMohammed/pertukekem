import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../authentication/viewmodel/auth_viewmodel.dart';
import '../../../authentication/model/user_model.dart';
import '../../viewmodel/user_profile_viewmodel.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel userProfile;

  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _hasChanges = false;
  bool _isPhoneVerificationInProgress = false;
  bool _isOtpSent = false;
  String? _verificationId;
  String? _originalPhoneNumber;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _firstNameController.text = widget.userProfile.firstName;
    _lastNameController.text = widget.userProfile.lastName;
    _phoneController.text = widget.userProfile.phoneNumber;
    _originalPhoneNumber = widget.userProfile.phoneNumber;

    // Add listeners to detect changes
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final hasChanges =
        _firstNameController.text.trim() != widget.userProfile.firstName ||
        _lastNameController.text.trim() != widget.userProfile.lastName ||
        _phoneController.text.trim() != widget.userProfile.phoneNumber;

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
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = context.read<AuthViewModel>();
    final userProfileViewModel = context.read<UserProfileViewModel>();
    final userId = authViewModel.user?.userId;

    if (userId == null) {
      _showErrorSnackBar('User not authenticated');
      return;
    }

    // Check if phone number has changed and needs verification
    final newPhoneNumber = _phoneController.text.trim();
    final phoneChanged = newPhoneNumber != _originalPhoneNumber;

    if (phoneChanged && !_isOtpSent) {
      // Phone number changed but OTP not sent yet
      _showErrorSnackBar('Please verify your new phone number first');
      await _initiatePhoneVerification();
      return;
    }

    if (phoneChanged && _isOtpSent) {
      // Phone number changed and OTP sent, but not verified yet
      _showErrorSnackBar('Please verify the OTP before saving');
      return;
    }

    // Save other profile information (phone number already updated during verification)
    final success = await userProfileViewModel.updateUserProfile(
      userId: userId,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      // Refresh auth viewmodel to get updated data from Firestore
      await authViewModel.refreshUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Return true to indicate success
    } else {
      final error = userProfileViewModel.error ?? 'Failed to update profile';
      _showErrorSnackBar(error);
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
      child: Consumer<UserProfileViewModel>(
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
                          _hasChanges && !viewModel.isUpdating
                              ? colorScheme.primary
                              : colorScheme.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow:
                          _hasChanges && !viewModel.isUpdating
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
                      onPressed:
                          _hasChanges && !viewModel.isUpdating
                              ? _saveProfile
                              : null,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            _hasChanges && !viewModel.isUpdating
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
                      child:
                          viewModel.isUpdating
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary,
                                  ),
                                ),
                              )
                              : Row(
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
                                  'Edit Profile',
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Update your personal information',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Profile Picture Section
                          Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: Stack(
                                children: [
                                  Hero(
                                    tag: 'profile_picture',
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            colorScheme.primary.withOpacity(
                                              0.1,
                                            ),
                                            colorScheme.secondary.withOpacity(
                                              0.1,
                                            ),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: colorScheme.primary
                                              .withOpacity(0.3),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.primary
                                                .withOpacity(0.2),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: _buildProfileImage(
                                          viewModel,
                                          colorScheme,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Material(
                                      elevation: 8,
                                      shape: const CircleBorder(),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: colorScheme.surface,
                                            width: 3,
                                          ),
                                        ),
                                        child: IconButton(
                                          onPressed:
                                              () => _showImagePickerOptions(
                                                context,
                                                viewModel,
                                              ),
                                          icon:
                                              viewModel.isUploadingImage
                                                  ? SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            colorScheme
                                                                .onPrimary,
                                                          ),
                                                    ),
                                                  )
                                                  : Icon(
                                                    Icons.camera_alt_rounded,
                                                    size: 20,
                                                    color:
                                                        colorScheme.onPrimary,
                                                  ),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                              const SizedBox(height: 20),
                              _buildModernTextField(
                                controller: _firstNameController,
                                label: 'First Name',
                                hint: 'Enter your first name',
                                icon: Icons.person_outline_rounded,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'First name is required';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'First name must be at least 2 characters';
                                  }
                                  return null;
                                },
                                textCapitalization: TextCapitalization.words,
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 20),
                              _buildModernTextField(
                                controller: _lastNameController,
                                label: 'Last Name',
                                hint: 'Enter your last name',
                                icon: Icons.person_outline_rounded,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Last name is required';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Last name must be at least 2 characters';
                                  }
                                  return null;
                                },
                                textCapitalization: TextCapitalization.words,
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 20),
                              _buildPhoneNumberField(colorScheme),
                              if (_phoneController.text.trim() !=
                                      _originalPhoneNumber &&
                                  !_isOtpSent)
                                const SizedBox(height: 12),
                              if (_phoneController.text.trim() !=
                                      _originalPhoneNumber &&
                                  !_isOtpSent)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.primary.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: colorScheme.primary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Phone number changed. Click the send button to verify via OTP.',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color: colorScheme.primary,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_phoneController.text.trim() ==
                                      _originalPhoneNumber &&
                                  widget.userProfile.isPhoneVerified)
                                const SizedBox(height: 12),
                              if (_phoneController.text.trim() ==
                                      _originalPhoneNumber &&
                                  widget.userProfile.isPhoneVerified)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        color: Colors.green.shade700,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Phone number is verified',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color: Colors.green.shade700,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
                              const SizedBox(height: 20),
                              _buildReadOnlyField(
                                context,
                                label: 'Email Address',
                                value: widget.userProfile.email,
                                icon: Icons.email_outlined,
                                isVerified: widget.userProfile.isEmailVerified,
                                verificationText:
                                    widget.userProfile.isEmailVerified
                                        ? 'Verified'
                                        : 'Unverified',
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Email cannot be changed. Contact support if you need to update your email address.',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.primary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient:
                                    _hasChanges && !viewModel.isUpdating
                                        ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            colorScheme.primary,
                                            colorScheme.primary.withOpacity(
                                              0.8,
                                            ),
                                          ],
                                        )
                                        : null,
                                color:
                                    !_hasChanges || viewModel.isUpdating
                                        ? colorScheme.outline.withOpacity(0.2)
                                        : null,
                                boxShadow:
                                    _hasChanges && !viewModel.isUpdating
                                        ? [
                                          BoxShadow(
                                            color: colorScheme.primary
                                                .withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                        : null,
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    _hasChanges && !viewModel.isUpdating
                                        ? _saveProfile
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor:
                                      _hasChanges && !viewModel.isUpdating
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurface.withOpacity(
                                            0.4,
                                          ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child:
                                    viewModel.isUpdating
                                        ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(colorScheme.onPrimary),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Saving Changes...',
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        )
                                        : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.save_rounded, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Save Changes',
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
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

  Widget _buildProfileImage(
    UserProfileViewModel viewModel,
    ColorScheme colorScheme,
  ) {
    // Show temp image if available, otherwise show current profile picture
    final imageUrl =
        viewModel.tempProfilePictureUrl ?? widget.userProfile.profilePicture;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderAvatar(colorScheme);
        },
      );
    } else {
      return _buildPlaceholderAvatar(colorScheme);
    }
  }

  Widget _buildPlaceholderAvatar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: 60,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  void _showImagePickerOptions(
    BuildContext context,
    UserProfileViewModel viewModel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final authViewModel = context.read<AuthViewModel>();
    final userId = authViewModel.user?.userId;

    if (userId == null) {
      _showErrorSnackBar('User not authenticated');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Profile Picture',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageOption(
                      context,
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () async {
                        Navigator.of(context).pop();
                        final success = await viewModel
                            .pickAndUploadProfilePicture(userId);
                        if (success) {
                          setState(() {
                            _hasChanges = true;
                          });
                          _showSuccessSnackBar(
                            'Profile picture updated successfully',
                          );
                        } else if (viewModel.error != null) {
                          _showErrorSnackBar(viewModel.error!);
                        }
                      },
                      colorScheme: colorScheme,
                    ),
                    _buildImageOption(
                      context,
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () async {
                        Navigator.of(context).pop();
                        final success = await viewModel
                            .takeAndUploadProfilePicture(userId);
                        if (success) {
                          setState(() {
                            _hasChanges = true;
                          });
                          _showSuccessSnackBar(
                            'Profile picture updated successfully',
                          );
                        } else if (viewModel.error != null) {
                          _showErrorSnackBar(viewModel.error!);
                        }
                      },
                      colorScheme: colorScheme,
                    ),
                    if (widget.userProfile.profilePicture != null &&
                        widget.userProfile.profilePicture!.isNotEmpty)
                      _buildImageOption(
                        context,
                        icon: Icons.delete_rounded,
                        label: 'Remove',
                        onTap: () async {
                          Navigator.of(context).pop();
                          final success = await viewModel.removeProfilePicture(
                            userId,
                          );
                          if (success) {
                            setState(() {
                              _hasChanges = true;
                            });
                            _showSuccessSnackBar(
                              'Profile picture removed successfully',
                            );
                          } else if (viewModel.error != null) {
                            _showErrorSnackBar(viewModel.error!);
                          }
                        },
                        colorScheme: colorScheme,
                        isDestructive: true,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildImageOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isDestructive
                  ? colorScheme.errorContainer.withOpacity(0.3)
                  : colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDestructive
                    ? colorScheme.error.withOpacity(0.3)
                    : colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isDestructive ? colorScheme.error : colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isDestructive ? colorScheme.error : colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _initiatePhoneVerification() async {
    final newPhoneNumber = _phoneController.text.trim();
    if (newPhoneNumber == _originalPhoneNumber) {
      _showErrorSnackBar('Phone number is the same as current number');
      return;
    }

    if (newPhoneNumber.isEmpty) {
      _showErrorSnackBar('Please enter a phone number');
      return;
    }

    // Validate phone number format
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(newPhoneNumber)) {
      _showErrorSnackBar('Please enter a valid phone number');
      return;
    }

    final authViewModel = context.read<AuthViewModel>();

    setState(() {
      _isPhoneVerificationInProgress = true;
    });

    try {
      await authViewModel.sendPhoneVerification(
        phoneNumber: newPhoneNumber,
        onCodeSent: (verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
            _isPhoneVerificationInProgress = false;
          });
          _showSuccessSnackBar('OTP sent to $newPhoneNumber');
        },
        onError: (error) {
          setState(() {
            _isPhoneVerificationInProgress = false;
            _isOtpSent = false;
          });

          // Handle specific errors for phone verification
          String errorMessage = error;
          if (error.contains('invalid-phone-number')) {
            errorMessage =
                'Invalid phone number format. Please include country code.';
          } else if (error.contains('too-many-requests')) {
            errorMessage = 'Too many SMS requests. Please try again later.';
          } else if (error.contains('quota-exceeded')) {
            errorMessage = 'SMS quota exceeded. Please try again tomorrow.';
          }

          _showErrorSnackBar(errorMessage);
        },
      );
    } catch (e) {
      setState(() {
        _isPhoneVerificationInProgress = false;
        _isOtpSent = false;
      });
      _showErrorSnackBar('Failed to send OTP: ${e.toString()}');
    }
  }

  Future<void> _verifyPhoneOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      _showErrorSnackBar('Please enter a valid 6-digit OTP');
      return;
    }

    if (_verificationId == null) {
      _showErrorSnackBar('Verification ID not found. Please try again.');
      return;
    }

    final authViewModel = context.read<AuthViewModel>();

    setState(() {
      _isPhoneVerificationInProgress = true;
    });

    try {
      // Use the new updatePhoneNumber method for existing users
      await authViewModel.updatePhoneNumber(_verificationId!, otp);

      setState(() {
        _isPhoneVerificationInProgress = false;
        _isOtpSent = false;
        _verificationId = null;
        _originalPhoneNumber = _phoneController.text.trim();
      });

      _otpController.clear();
      _showSuccessSnackBar('Phone number verified and updated successfully');

      // Refresh user data
      await authViewModel.refreshUserData();
    } catch (e) {
      setState(() {
        _isPhoneVerificationInProgress = false;
      });

      // Handle specific Firebase Auth errors
      String errorMessage = 'Failed to verify OTP';
      if (e.toString().contains('invalid-verification-code')) {
        errorMessage = 'Invalid OTP code. Please check and try again.';
      } else if (e.toString().contains('session-expired')) {
        errorMessage = 'OTP has expired. Please request a new one.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many attempts. Please try again later.';
      } else {
        errorMessage = 'Failed to verify OTP: ${e.toString()}';
      }

      _showErrorSnackBar(errorMessage);
    }
  }

  void _cancelPhoneVerification() {
    setState(() {
      _isOtpSent = false;
      _isPhoneVerificationInProgress = false;
      _verificationId = null;
      _phoneController.text = _originalPhoneNumber ?? '';
    });
    _otpController.clear();
  }

  Widget _buildPhoneNumberField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 12),
            if (_phoneController.text.trim() != _originalPhoneNumber &&
                !_isOtpSent &&
                !_isPhoneVerificationInProgress)
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _initiatePhoneVerification,
                  icon: Icon(
                    Icons.send_rounded,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                  tooltip: 'Send OTP',
                ),
              ),
            if (_isPhoneVerificationInProgress)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_isOtpSent) ...[
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.security_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Verify Phone Number',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to ${_phoneController.text.trim()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          hintText: 'Enter OTP',
                          counterText: '',
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed:
                          _isPhoneVerificationInProgress
                              ? null
                              : _verifyPhoneOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isPhoneVerificationInProgress
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary,
                                  ),
                                ),
                              )
                              : const Text('Verify'),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed:
                          _isPhoneVerificationInProgress
                              ? null
                              : _initiatePhoneVerification,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Resend'),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _cancelPhoneVerification,
                      icon: Icon(Icons.close_rounded, color: colorScheme.error),
                      tooltip: 'Cancel',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (_phoneController.text.trim() != _originalPhoneNumber && !_isOtpSent)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Phone number changed. Click the send button to verify via OTP.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
