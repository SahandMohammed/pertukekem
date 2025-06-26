import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pertukekem/features/authentication/viewmodel/auth_viewmodel.dart';
import 'package:pertukekem/features/authentication/view/change_password_screen.dart';
import '../../../payments/view/store_transactions_screen.dart';
import '../../viewmodel/store_profile_viewmodel.dart';
import '../../viewmodel/user_profile_viewmodel.dart';
import 'edit_store_profile_screen.dart';
import '../customer/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // ProfileViewModel is provided by the parent dashboard; only provide UserProfileViewModel here
    return ChangeNotifierProvider(
      create: (_) => UserProfileViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings (Coming Soon)'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header with User Card
              _buildUserProfileCard(context, user, textTheme, colorScheme),
              const SizedBox(height: 24),

              // Quick Stats
              Text(
                'Business Stats',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Products',
                      '0', // TODO: Get actual product count
                      Icons.inventory_outlined,
                      colorScheme.primaryContainer,
                      colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Sales',
                      '0', // TODO: Get actual sales count
                      Icons.trending_up_outlined,
                      colorScheme.tertiaryContainer,
                      colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Menu Options - Account
              Text(
                'Account',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(context, [
                _MenuOption(
                  icon: Icons.store_outlined,
                  title: 'Edit Store Profile',
                  subtitle: 'Update store information and settings',
                  onTap: () async {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) =>
                              const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      // Fetch store data from the ProfileViewModel
                      final profileViewModel = Provider.of<ProfileViewModel>(
                        context,
                        listen: false,
                      );
                      final storeData = await profileViewModel.fetchStoreData();

                      if (context.mounted) {
                        Navigator.of(context).pop(); // Remove loading dialog
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder:
                                (context) => ChangeNotifierProvider.value(
                                  value: profileViewModel,
                                  child: EditStoreProfileScreen(
                                    userProfile: user,
                                    storeProfile: storeData,
                                  ),
                                ),
                          ),
                        );
                        // Refresh profile data if edit was successful
                        if (result == true && context.mounted) {
                          setState(() {}); // Force rebuild after edit

                          // Show success message (data should already be updated via optimistic updates)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Store profile updated successfully'),
                                ],
                              ),
                              backgroundColor: colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );

                          // Optional: Light refresh in background to ensure server consistency
                          // (Remove the aggressive immediate refresh that might override optimistic updates)
                          Future.delayed(const Duration(seconds: 2), () async {
                            if (context.mounted) {
                              // Background server sync for consistency
                              await authViewModel.refreshUserData();
                              await profileViewModel.fetchStoreData();
                              // Completed background refresh
                            }
                          });
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.of(context).pop(); // Remove loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error loading store data: \\${e.toString()}',
                            ),
                            backgroundColor: colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                _MenuOption(
                  icon: Icons.person_outline,
                  title: 'Edit Personal Profile',
                  subtitle: 'Update your personal information',
                  onTap: () async {
                    try {
                      final userProfileViewModel =
                          Provider.of<UserProfileViewModel>(
                            context,
                            listen: false,
                          );

                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder:
                              (context) => MultiProvider(
                                providers: [
                                  ChangeNotifierProvider.value(
                                    value: userProfileViewModel,
                                  ),
                                  ChangeNotifierProvider.value(
                                    value: Provider.of<AuthViewModel>(
                                      context,
                                      listen: false,
                                    ),
                                  ),
                                ],
                                child: EditProfileScreen(userProfile: user),
                              ),
                        ),
                      );

                      if (result == true && context.mounted) {
                        // Refresh the AuthViewModel to get updated user data
                        final authViewModel = Provider.of<AuthViewModel>(
                          context,
                          listen: false,
                        );
                        await authViewModel.refreshUserData();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text('Personal profile updated successfully'),
                              ],
                            ),
                            backgroundColor: colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                _MenuOption(
                  icon: Icons.security_outlined,
                  title: 'Security',
                  subtitle: 'Password and security settings',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 16),

              // Business section
              Text(
                'Business',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(context, [
                _MenuOption(
                  icon: Icons.receipt_long_outlined,
                  title: 'Sales Transactions',
                  subtitle: 'View your transaction history',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StoreTransactionsScreen(),
                      ),
                    );
                  },
                ),
                _MenuOption(
                  icon: Icons.analytics_outlined,
                  title: 'Performance Analytics',
                  subtitle: 'Track your business performance',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Analytics coming soon!')),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 16),

              // Support & Info
              Text(
                'Support & Information',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(context, [
                _MenuOption(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  subtitle: 'Get help with your store',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Help Center (Coming Soon)'),
                      ),
                    );
                  },
                ),
                _MenuOption(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'Learn more about PertuKeKem',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('About (Coming Soon)')),
                    );
                  },
                ),
                _MenuOption(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  onTap: () => _showSignOutDialog(context),
                  isDestructive: true,
                ),
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileCard(
    BuildContext context,
    user,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceVariant.withOpacity(0.3),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Profile Picture and User Info - wrapped in a single Consumer2
                Expanded(
                  child: Consumer2<ProfileViewModel, AuthViewModel>(
                    builder: (context, profileViewModel, authViewModel, child) {
                      // Always prefer storeData from ProfileViewModel if available
                      final currentUser = authViewModel.user ?? user;
                      final storeData = profileViewModel.storeData;
                      final storeName =
                          storeData != null && storeData.storeName.isNotEmpty
                              ? storeData.storeName
                              : currentUser.storeName;
                      final storeDescription = storeData?.description ?? '';
                      final phoneNumber =
                          storeData?.contactInfo != null &&
                                  storeData!.contactInfo.isNotEmpty
                              ? (storeData.contactInfo.firstWhere(
                                    (info) => info['type'] == 'phone',
                                    orElse:
                                        () => {
                                          'value': currentUser.phoneNumber,
                                        },
                                  )['value'] ??
                                  currentUser.phoneNumber)
                              : currentUser.phoneNumber;

                      return Row(
                        children: [
                          // Profile Picture
                          Hero(
                            tag: 'store_profile_picture',
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colorScheme.primary.withOpacity(0.1),
                                    colorScheme.secondary.withOpacity(0.1),
                                  ],
                                ),
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child:
                                    profileViewModel.isUploadingImage
                                        ? Container(
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                strokeWidth: 3,
                                                value:
                                                    profileViewModel
                                                        .uploadProgress,
                                                backgroundColor: colorScheme
                                                    .onPrimaryContainer
                                                    .withOpacity(0.3),
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(colorScheme.primary),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${(profileViewModel.uploadProgress * 100).toInt()}%',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      colorScheme
                                                          .onPrimaryContainer,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                        : profileViewModel
                                                    .storeProfilePicture !=
                                                null &&
                                            profileViewModel
                                                .storeProfilePicture!
                                                .isNotEmpty
                                        ? Image.network(
                                          profileViewModel.storeProfilePicture!,
                                          fit: BoxFit.cover,
                                          width: 80,
                                          height: 80,
                                          loadingBuilder: (
                                            context,
                                            child,
                                            loadingProgress,
                                          ) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color:
                                                    colorScheme
                                                        .primaryContainer,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    colorScheme
                                                        .primaryContainer,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.store,
                                                size: 40,
                                                color:
                                                    colorScheme
                                                        .onPrimaryContainer,
                                              ),
                                            );
                                          },
                                        )
                                        : Container(
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.store,
                                            size: 40,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // User Information
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${currentUser.firstName} ${currentUser.lastName}',
                                        style: textTheme.titleLarge?.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (storeName != null &&
                                    storeName.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    storeName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (storeDescription.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    storeDescription,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  currentUser.email,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  phoneNumber,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Camera button
                Consumer<ProfileViewModel>(
                  builder: (context, profileViewModel, child) {
                    return Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed:
                            (profileViewModel.isUploadingImage ||
                                    profileViewModel.isRemovingImage)
                                ? null
                                : () => _showImageSourceDialog(
                                  context,
                                  profileViewModel,
                                ),
                        icon: Icon(
                          Icons.camera_alt_rounded,
                          color:
                              (profileViewModel.isUploadingImage ||
                                      profileViewModel.isRemovingImage)
                                  ? colorScheme.outline
                                  : Colors.black,
                          size: 20,
                        ),
                        tooltip: 'Update Profile Picture',
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16), // Additional Info Row
            Consumer<AuthViewModel>(
              builder: (context, authViewModel, child) {
                final currentUser = authViewModel.user ?? user;
                return Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentUser.createdAt != null
                          ? 'Store since ${_formatDate(currentUser.createdAt!)}'
                          : 'New store',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'STORE',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color backgroundColor,
    Color foregroundColor,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: foregroundColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, List<_MenuOption> options) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children:
            options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      option.icon,
                      color:
                          option.isDestructive
                              ? colorScheme.error
                              : colorScheme.onSurface,
                    ),
                    title: Text(
                      option.title,
                      style: TextStyle(
                        color:
                            option.isDestructive
                                ? colorScheme.error
                                : colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(option.subtitle),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: option.onTap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top:
                            index == 0
                                ? const Radius.circular(16)
                                : Radius.zero,
                        bottom:
                            index == options.length - 1
                                ? const Radius.circular(16)
                                : Radius.zero,
                      ),
                    ),
                  ),
                  if (index < options.length - 1)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                ],
              );
            }).toList(),
      ),
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
            builder:
                (context, profileViewModel, child) => Container(
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose how you want to update your profile picture',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed:
                                  profileViewModel.isRemovingImage
                                      ? null
                                      : () {
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
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
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

    if (confirmed == true && context.mounted) {
      final errorMessage = await profileViewModel.removeProfilePicture();

      if (context.mounted) {
        if (errorMessage == null) {
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

class _MenuOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  _MenuOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });
}
