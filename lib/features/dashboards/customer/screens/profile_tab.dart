import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guest User',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Book lover and reader',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Edit profile
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit Profile (Coming Soon)'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
            ),
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
                  child: _buildStatCard(
                    context,
                    'Books Saved',
                    '0',
                    Icons.bookmark_outline,
                    colorScheme.primaryContainer,
                    colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Purchases',
                    '0',
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
                onTap: () => _showComingSoon(context, 'Saved Books'),
              ),
              _MenuOption(
                icon: Icons.history,
                title: 'Purchase History',
                subtitle: 'View your past orders',
                onTap: () => _showComingSoon(context, 'Purchase History'),
              ),
              _MenuOption(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage your notifications',
                onTap: () => _showComingSoon(context, 'Notifications'),
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
                onTap: () => _showComingSoon(context, 'Help & Support'),
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
    );
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
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Implement sign out logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sign out functionality (Coming Soon)'),
                      duration: Duration(seconds: 2),
                    ),
                  );
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
