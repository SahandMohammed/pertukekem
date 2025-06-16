import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../authentication/viewmodel/auth_viewmodel.dart';
import '../../../authentication/model/user_model.dart';
import '../../../payments/view/user_cards_screen.dart';
import '../../../payments/view/user_transaction_history_screen.dart';
import '../../../library/notifiers/saved_books_notifier.dart';
import 'manage_address_screen.dart';
import 'saved_books_screen.dart';
import 'edit_profile_screen.dart';
import '../../viewmodel/store_profile_viewmodel.dart';
import '../../services/user_profile_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final UserProfileService _userProfileService = UserProfileService();
  UserModel? _userProfile;
  int _savedBooksCount = 0;
  int _purchaseCount = 0;
  bool _isLoading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    // Listen to saved books changes
    SavedBooksNotifier().addListener(_onSavedBooksChanged);
  }

  @override
  void dispose() {
    SavedBooksNotifier().removeListener(_onSavedBooksChanged);
    super.dispose();
  }

  void _onSavedBooksChanged() {
    // Refresh stats when saved books change
    _refreshStats();
  }

  Future<void> _loadUserProfile() async {
    final authViewModel = context.read<AuthViewModel>();
    final user = authViewModel.user;

    if (user?.userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'User not authenticated';
      });
      return;
    }

    try {
      final userProfile = await _userProfileService.getUserProfile(
        user!.userId,
      );
      final savedBooksCount = await _userProfileService.getUserSavedBooksCount(
        user.userId,
      );
      final purchaseCount = await _userProfileService.getUserPurchaseCount(
        user.userId,
      );

      setState(() {
        _userProfile = userProfile;
        _savedBooksCount = savedBooksCount;
        _purchaseCount = purchaseCount;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshStats() async {
    final authViewModel = context.read<AuthViewModel>();
    final user = authViewModel.user;

    if (user?.userId == null) return;

    try {
      final savedBooksCount = await _userProfileService.getUserSavedBooksCount(
        user!.userId,
      );
      final purchaseCount = await _userProfileService.getUserPurchaseCount(
        user.userId,
      );

      if (mounted) {
        setState(() {
          _savedBooksCount = savedBooksCount;
          _purchaseCount = purchaseCount;
        });
      }
    } catch (e) {
      // Silently handle errors for stats refresh
      debugPrint('Error refreshing stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadUserProfile,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to settings
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading profile',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUserProfile,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadUserProfile,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header with User Card
                      _buildUserProfileCard(),
                      const SizedBox(height: 24),

                      // Quick Stats
                      Text(
                        'Quick Stats',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const SavedBooksScreen(),
                                  ),
                                );

                                // Refresh stats when returning from saved books screen
                                if (mounted) {
                                  _refreshStats();
                                }
                              },
                              child: _buildStatCard(
                                context,
                                'Books Saved',
                                '$_savedBooksCount',
                                Icons.bookmark_outline,
                                colorScheme.primaryContainer,
                                colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Purchases',
                              '$_purchaseCount',
                              Icons.shopping_bag_outlined,
                              colorScheme.tertiaryContainer,
                              colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Menu Options
                      Text(
                        'Account',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(context, [
                        _MenuOption(
                          icon: Icons.bookmark_outline,
                          title: 'Saved Books',
                          subtitle: 'Your bookmarked items',
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SavedBooksScreen(),
                              ),
                            );

                            // Refresh stats when returning from saved books screen
                            if (mounted) {
                              _refreshStats();
                            }
                          },
                        ),
                        _MenuOption(
                          icon: Icons.location_on_outlined,
                          title: 'Manage Addresses',
                          subtitle: 'Add and edit delivery addresses',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => ChangeNotifierProvider(
                                      create: (context) {
                                        final profileViewModel =
                                            ProfileViewModel();
                                        final authViewModel =
                                            context.read<AuthViewModel>();
                                        profileViewModel.setAuthViewModel(
                                          authViewModel,
                                        );
                                        return profileViewModel;
                                      },
                                      child: const ManageAddressScreen(),
                                    ),
                              ),
                            );
                          },
                        ),
                        _MenuOption(
                          icon: Icons.credit_card_outlined,
                          title: 'My Cards',
                          subtitle: 'Manage saved payment cards',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const UserCardsScreen(),
                              ),
                            );
                          },
                        ),
                        _MenuOption(
                          icon: Icons.history,
                          title: 'Transaction History',
                          subtitle: 'View your payment history',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const UserTransactionHistoryScreen(),
                              ),
                            );
                          },
                        ),
                        _MenuOption(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'Manage your notifications',
                          onTap:
                              () => _showComingSoon(context, 'Notifications'),
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
                          title: 'Help & Support',
                          subtitle: 'Get help with your account',
                          onTap:
                              () => _showComingSoon(context, 'Help & Support'),
                        ),
                        _MenuOption(
                          icon: Icons.info_outline,
                          title: 'About',
                          subtitle: 'Learn more about PertuKeKem',
                          onTap: () => _showComingSoon(context, 'About'),
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

  Widget _buildUserProfileCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authUser =
        context
            .read<AuthViewModel>()
            .user; // Use data from either _userProfile or fallback to authUser
    final displayName =
        _userProfile != null
            ? '${_userProfile!.firstName} ${_userProfile!.lastName}'
            : (authUser != null
                ? '${authUser.firstName} ${authUser.lastName}'
                : 'Guest User');
    final displayEmail = _userProfile?.email ?? authUser?.email ?? 'No email';
    final displayPhone =
        _userProfile?.phoneNumber ?? authUser?.phoneNumber ?? 'Not provided';
    final profilePictureUrl =
        _userProfile?.profilePicture ?? authUser?.profilePicture;
    final isEmailVerified =
        _userProfile?.isEmailVerified ?? authUser?.isEmailVerified ?? false;
    final isPhoneVerified =
        _userProfile?.isPhoneVerified ?? authUser?.isPhoneVerified ?? false;
    final memberSince = _userProfile?.createdAt ?? authUser?.createdAt;
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
                // Profile Picture
                Hero(
                  tag: 'profile_picture',
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
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child:
                          profilePictureUrl != null &&
                                  profilePictureUrl.isNotEmpty
                              ? Image.network(
                                profilePictureUrl,
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          colorScheme.primaryContainer,
                                          colorScheme.secondaryContainer,
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
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
                                      size: 40,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  );
                                },
                              )
                              : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
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
                                  size: 40,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isEmailVerified || isPhoneVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 12,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Verified',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayEmail,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (displayPhone != 'Not provided')
                        Text(
                          displayPhone,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () async {
                      final profileToEdit = _userProfile ?? authUser;
                      if (profileToEdit != null) {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder:
                                (context) => EditProfileScreen(
                                  userProfile: profileToEdit,
                                ),
                          ),
                        );

                        // Refresh profile data if edit was successful
                        if (result == true) {
                          _loadUserProfile();
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Unable to load user profile'),
                            backgroundColor: colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      Icons.edit_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    tooltip: 'Edit Profile',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Additional Info Row
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  memberSince != null
                      ? 'Member since ${_formatDate(memberSince)}'
                      : 'New member',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const Spacer(),
                if (_userProfile?.roles.isNotEmpty ?? false)
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
                      _userProfile!.roles.first.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
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
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
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
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
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
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                ],
              );
            }).toList(),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature (Coming Soon)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await Provider.of<AuthViewModel>(
                      context,
                      listen: false,
                    ).signOut();
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
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
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
