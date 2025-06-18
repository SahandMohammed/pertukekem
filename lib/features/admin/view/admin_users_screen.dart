import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/admin_viewmodel.dart';
import '../widgets/admin_user_card.dart';
import '../widgets/admin_search_bar.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminViewModel = context.read<AdminViewModel>();
      if (adminViewModel.users.isEmpty) {
        adminViewModel.loadUsers();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final adminViewModel = context.read<AdminViewModel>();
      if (adminViewModel.hasMoreUsers && !adminViewModel.isLoadingUsers) {
        adminViewModel.loadUsers();
      }
    }
  }

  void _onSearch(String query) {
    final adminViewModel = context.read<AdminViewModel>();
    adminViewModel.searchUsers(query);
  }

  void _onRefresh() {
    final adminViewModel = context.read<AdminViewModel>();
    adminViewModel.clearSearch();
    _searchController.clear();
    adminViewModel.loadUsers(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (context, adminViewModel, child) {
        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AdminSearchBar(
                controller: _searchController,
                hintText: 'Search users by name or email...',
                onSearch: _onSearch,
                onClear: () {
                  _searchController.clear();
                  adminViewModel.clearSearch();
                },
              ),
            ),

            // Error Message
            if (adminViewModel.errorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        adminViewModel.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    IconButton(
                      onPressed: adminViewModel.clearError,
                      icon: Icon(Icons.close, color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),

            // Users List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _onRefresh(),
                child:
                    adminViewModel.users.isEmpty &&
                            !adminViewModel.isLoadingUsers
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                adminViewModel.isSearchMode
                                    ? 'No users found for "${adminViewModel.currentSearchTerm}"'
                                    : 'No users found',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                              if (!adminViewModel.isSearchMode) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _onRefresh,
                                  child: const Text('Refresh'),
                                ),
                              ],
                            ],
                          ),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount:
                              adminViewModel.users.length +
                              (adminViewModel.isLoadingUsers ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == adminViewModel.users.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final user = adminViewModel.users[index];
                            return AdminUserCard(
                              user: user,
                              onToggleBlock: (isBlocked) {
                                _showBlockConfirmation(
                                  context,
                                  user.fullName,
                                  isBlocked,
                                  () {
                                    adminViewModel.toggleUserBlock(
                                      user.userId,
                                      isBlocked,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showBlockConfirmation(
    BuildContext context,
    String userName,
    bool isBlocking,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${isBlocking ? 'Block' : 'Unblock'} User'),
            content: Text(
              'Are you sure you want to ${isBlocking ? 'block' : 'unblock'} $userName? '
              '${isBlocking ? 'This will prevent them from accessing the application.' : 'This will restore their access to the application.'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBlocking ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(isBlocking ? 'Block' : 'Unblock'),
              ),
            ],
          ),
    );
  }
}
