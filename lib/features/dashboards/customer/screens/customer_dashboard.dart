import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/customer_home_viewmodel.dart';
import 'home_tab.dart';
import 'search_tab.dart';
import 'stores_tab.dart';
import 'profile_tab.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) =>
              CustomerHomeViewModel()
                ..loadRecentlyListedItems()
                ..loadRecentlyJoinedStores(),
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            // Home Tab - Modern Dashboard
            HomeTab(
              searchController: _searchController,
              onTabChange: (index) => setState(() => _selectedIndex = index),
            ),
            // Search Tab - Search with Results
            SearchTab(searchController: _searchController),
            // Stores Tab - All Stores
            const StoresTab(),
            // Profile Tab
            const ProfileTab(),
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
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.store_outlined),
              selectedIcon: Icon(Icons.store),
              label: 'Stores',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
