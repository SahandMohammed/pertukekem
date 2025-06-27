import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/admin_viewmodel.dart';
import '../widgets/admin_access_widget.dart';
import 'admin_users_screen.dart';
import 'admin_stores_screen.dart';
import 'admin_listings_screen.dart';
import '../widgets/admin_stats_card.dart';
import '../widgets/admin_shimmer_widgets.dart';
import '../../authentication/viewmodel/auth_viewmodel.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminViewModel = context.read<AdminViewModel>();
      adminViewModel.loadStatistics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // Close dialog
                  try {
                    await context.read<AuthViewModel>().signOut();
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminAccessWidget(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showSignOutDialog(context),
              tooltip: 'Sign Out',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onPrimary.withOpacity(0.7),
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            tabs: const [
              Tab(text: 'Customers', icon: Icon(Icons.person)),
              Tab(text: 'Stores', icon: Icon(Icons.store)),
              Tab(text: 'Listings', icon: Icon(Icons.book)),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.primary,
              child: Consumer<AdminViewModel>(
                builder: (context, adminViewModel, child) {
                  if (adminViewModel.isLoadingStats) {
                    return AdminShimmerWidgets.statisticsShimmer();
                  }

                  final stats = adminViewModel.statistics;
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: AdminStatsCard(
                            title: 'Total Customers',
                            value: stats['totalCustomers']?.toString() ?? '0',
                            icon: Icons.person,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AdminStatsCard(
                            title: 'Total Stores',
                            value: stats['totalStores']?.toString() ?? '0',
                            icon: Icons.store,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AdminStatsCard(
                            title: 'Active Listings',
                            value: stats['totalListings']?.toString() ?? '0',
                            icon: Icons.book,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AdminStatsCard(
                            title: 'Blocked Users',
                            value: stats['blockedUsers']?.toString() ?? '0',
                            icon: Icons.block,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AdminUsersScreen(),
                  AdminStoresScreen(),
                  AdminListingsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
