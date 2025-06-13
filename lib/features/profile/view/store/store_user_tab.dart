import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pertukekem/features/authentication/viewmodel/auth_viewmodel.dart';
import '../../../payments/view/store_transactions_screen.dart';
import '../../viewmodel/store_profile_viewmodel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ChangeNotifierProvider(
      create: (context) {
        final profileViewModel = ProfileViewModel();
        profileViewModel.setAuthViewModel(authViewModel);
        // Fetch store profile picture when view model is created
        profileViewModel.fetchStoreProfilePicture();
        return profileViewModel;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          elevation: 0,
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Profile picture with upload functionality
                    Consumer<ProfileViewModel>(
                      builder: (context, profileViewModel, child) {
                        return _buildProfilePictureSection(
                          context,
                          user,
                          profileViewModel,
                          colorScheme,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      '${user.firstName} ${user.lastName}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user.storeName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.storeName!,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Email and phone
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.email,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.phoneNumber,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Account settings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Settings list
                    Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildProfileListItem(
                            context,
                            Icons.person_outline,
                            'Edit Profile',
                            () {
                              // TODO: Navigate to edit profile screen
                            },
                          ),
                          _buildDivider(),
                          _buildProfileListItem(
                            context,
                            Icons.store_outlined,
                            'Store Settings',
                            () {
                              // TODO: Navigate to store settings
                            },
                          ),
                          _buildDivider(),
                          _buildProfileListItem(
                            context,
                            Icons.security_outlined,
                            'Security',
                            () {
                              // TODO: Navigate to security settings
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Business section
                    Text(
                      'Business',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildProfileListItem(
                            context,
                            Icons.receipt_long_outlined,
                            'Sales Transactions',
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const StoreTransactionsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildProfileListItem(
                            context,
                            Icons.analytics_outlined,
                            'Performance Analytics',
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Analytics coming soon!'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Support section
                    Text(
                      'Support',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildProfileListItem(
                            context,
                            Icons.help_outline,
                            'Help Center',
                            () {
                              // TODO: Navigate to help center
                            },
                          ),
                          _buildDivider(),
                          _buildProfileListItem(
                            context,
                            Icons.info_outline,
                            'About',
                            () {
                              // TODO: Navigate to about page
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sign out button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showSignOutDialog(context),
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.errorContainer,
                          foregroundColor: colorScheme.onErrorContainer,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(
    BuildContext context,
    user,
    ProfileViewModel profileViewModel,
    ColorScheme colorScheme,
  ) {
    return Stack(
      children: [
        // Profile picture
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            child:
                profileViewModel.isUploadingImage
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          value: profileViewModel.uploadProgress,
                          backgroundColor: colorScheme.onPrimaryContainer
                              .withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Uploading ${(profileViewModel.uploadProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                    : profileViewModel.isRemovingImage
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Removing...',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                    : profileViewModel.storeProfilePicture != null
                    ? ClipOval(
                      child: Image.network(
                        profileViewModel.storeProfilePicture!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder:
                            (_, __, ___) => Text(
                              '${user.firstName[0]}${user.lastName[0]}',
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                    )
                    : Text(
                      '${user.firstName[0]}${user.lastName[0]}',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
        // Upload/Edit button
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap:
                (profileViewModel.isUploadingImage ||
                        profileViewModel.isRemovingImage)
                    ? null
                    : () => _showImageSourceDialog(context, profileViewModel),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    (profileViewModel.isUploadingImage ||
                            profileViewModel.isRemovingImage)
                        ? colorScheme.outline
                        : colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:
                  (profileViewModel.isUploadingImage ||
                          profileViewModel.isRemovingImage)
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Icon(
                        Icons.camera_alt_rounded,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
            ),
          ),
        ),
      ],
    );
  }
  void _showImageSourceDialog(
    BuildContext context,
    ProfileViewModel profileViewModel,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: !profileViewModel.isRemovingImage,
      enableDrag: !profileViewModel.isRemovingImage,
      builder:
          (context) => Consumer<ProfileViewModel>(
            builder: (context, profileViewModel, child) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Update Profile Picture',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how you want to update your profile picture',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: _buildImageSourceOption(
                            context,
                            icon: Icons.camera_alt_rounded,
                            label: 'Camera',
                            subtitle: 'Take a new photo',
                            onTap: () {
                              Navigator.pop(context);
                              _handleImageSelection(
                                context,
                                profileViewModel,
                                ImageSource.camera,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildImageSourceOption(
                            context,
                            icon: Icons.photo_library_rounded,
                            label: 'Gallery',
                            subtitle: 'Choose from photos',
                            onTap: () {
                              Navigator.pop(context);
                              _handleImageSelection(
                                context,
                                profileViewModel,
                                ImageSource.gallery,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    if (profileViewModel.storeProfilePicture != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,                        child: OutlinedButton.icon(
                          onPressed:
                              profileViewModel.isRemovingImage
                                  ? null
                                  : () {
                                    debugPrint('🗑️ Remove Photo button clicked');
                                    Navigator.pop(context);
                                    _handleRemoveProfilePicture(
                                      context,
                                      profileViewModel,
                                    );
                                  },
                          icon:
                              profileViewModel.isRemovingImage
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.delete_outline),
                          label: Text(
                            profileViewModel.isRemovingImage
                                ? 'Removing...'
                                : 'Remove Photo',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildImageSourceOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.onPrimary, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageSelection(
    BuildContext context,
    ProfileViewModel profileViewModel,
    ImageSource source,
  ) async {
    try {
      final imageFile = await profileViewModel.pickImage(source);
      if (imageFile == null) return;

      final errorMessage = await profileViewModel.updateProfilePicture(
        imageFile,
      );

      if (context.mounted) {
        if (errorMessage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Profile picture updated successfully!'),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  Future<void> _handleRemoveProfilePicture(
    BuildContext context,
    ProfileViewModel profileViewModel,
  ) async {
    debugPrint('🗑️ Starting profile picture removal process...');
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Profile Picture'),
            content: const Text(
              'Are you sure you want to remove your profile picture?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
    );

    debugPrint('🗑️ User confirmed removal: $confirmed');

    if (confirmed == true && context.mounted) {
      debugPrint('🗑️ Calling removeProfilePicture method...');
      final errorMessage = await profileViewModel.removeProfilePicture();
      debugPrint('🗑️ removeProfilePicture completed with error: $errorMessage');

      if (context.mounted) {
        if (errorMessage == null) {
          debugPrint('🗑️ Showing success message...');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Profile picture removed successfully!'),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildProfileListItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, indent: 56, endIndent: 16);
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (result == true && context.mounted) {
      try {
        await Provider.of<AuthViewModel>(context, listen: false).signOut();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
