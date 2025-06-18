import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/admin_viewmodel.dart';
import '../widgets/admin_store_card.dart';
import '../widgets/admin_search_bar.dart';
import '../widgets/admin_shimmer_widgets.dart';

class AdminStoresScreen extends StatefulWidget {
  const AdminStoresScreen({super.key});

  @override
  State<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends State<AdminStoresScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminViewModel = context.read<AdminViewModel>();
      if (adminViewModel.stores.isEmpty) {
        adminViewModel.loadStores();
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
      if (adminViewModel.hasMoreStores && !adminViewModel.isLoadingStores) {
        adminViewModel.loadStores();
      }
    }
  }

  void _onSearch(String query) {
    final adminViewModel = context.read<AdminViewModel>();
    adminViewModel.searchStores(query);
  }

  void _onRefresh() {
    final adminViewModel = context.read<AdminViewModel>();
    adminViewModel.clearSearch();
    _searchController.clear();
    adminViewModel.loadStores(refresh: true);
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
                hintText: 'Search stores by name...',
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
              ), // Stores List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _onRefresh(),
                child:
                    adminViewModel.isLoadingStores &&
                            adminViewModel.stores.isEmpty
                        ? AdminShimmerWidgets.shimmerList(
                          shimmerItem: AdminShimmerWidgets.storeCardShimmer(),
                        )
                        : adminViewModel.stores.isEmpty &&
                            !adminViewModel.isLoadingStores
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.store_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                adminViewModel.isSearchMode
                                    ? 'No stores found for "${adminViewModel.currentSearchTerm}"'
                                    : 'No stores found',
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
                              adminViewModel.stores.length +
                              (adminViewModel.isLoadingStores ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == adminViewModel.stores.length) {
                              return AdminShimmerWidgets.storeCardShimmer();
                            }

                            final store = adminViewModel.stores[index];
                            return AdminStoreCard(
                              store: store,
                              onToggleBlock: (isBlocked) {
                                _showBlockConfirmation(
                                  context,
                                  store.storeName,
                                  isBlocked,
                                  () {
                                    adminViewModel.toggleStoreBlock(
                                      store.storeId,
                                      store.ownerId,
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
    String storeName,
    bool isBlocking,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${isBlocking ? 'Block' : 'Unblock'} Store'),
            content: Text(
              'Are you sure you want to ${isBlocking ? 'block' : 'unblock'} "$storeName"? '
              '${isBlocking ? 'This will block the store owner and deactivate all store listings.' : 'This will restore the store owner\'s access.'}',
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
