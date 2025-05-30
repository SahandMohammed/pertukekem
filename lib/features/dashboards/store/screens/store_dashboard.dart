import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pertukekem/features/authentication/viewmodels/auth_viewmodel.dart';
import 'package:pertukekem/features/listings/view/manage_listings_screen.dart';
import 'package:pertukekem/features/orders/view/manage_orders_screen.dart';
import 'profile_screen.dart';

class StoreDashboard extends StatefulWidget {
  const StoreDashboard({super.key});

  @override
  State<StoreDashboard> createState() => _StoreDashboardState();
}

class _StoreDashboardState extends State<StoreDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.user;
    final storeName = user?.storeName ?? 'Store';

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home Tab
          Scaffold(
            appBar: AppBar(
              title: Text('Welcome, $storeName'),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // TODO: Show notifications
                  },
                ),
              ],
            ),
            body: const Center(child: Text('Home Screen (To be implemented)')),
          ),
          // Listings Tab
          const ManageListingsScreen(),
          // Orders Tab
          const ManageOrdersScreen(), // Profile Tab
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedIndex: _selectedIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Listings',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
