import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/admin_viewmodel.dart';
import '../widgets/admin_listing_card.dart';
import '../widgets/admin_search_bar.dart';
import '../widgets/admin_shimmer_widgets.dart';

class AdminListingsScreen extends StatefulWidget {
  const AdminListingsScreen({super.key});

  @override
  State<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends State<AdminListingsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminViewModel = context.read<AdminViewModel>();
      if (adminViewModel.listings.isEmpty) {
        adminViewModel.loadListings();
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
      if (adminViewModel.hasMoreListings && !adminViewModel.isLoadingListings) {
        adminViewModel.loadListings();
      }
    }
  }

  void _onSearch(String query) {
    final adminViewModel = context.read<AdminViewModel>();
    adminViewModel.searchListings(query);
  }

  void _onRefresh() {
    final adminViewModel = context.read<AdminViewModel>();
    adminViewModel.clearSearch();
    _searchController.clear();
    adminViewModel.loadListings(refresh: true);
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
                hintText: 'Search listings by title or author...',
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
              ), // Listings List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _onRefresh(),
                child:
                    adminViewModel.isLoadingListings &&
                            adminViewModel.listings.isEmpty
                        ? AdminShimmerWidgets.shimmerList(
                          shimmerItem: AdminShimmerWidgets.listingCardShimmer(),
                        )
                        : adminViewModel.listings.isEmpty &&
                            !adminViewModel.isLoadingListings
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.book_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                adminViewModel.isSearchMode
                                    ? 'No listings found for "${adminViewModel.currentSearchTerm}"'
                                    : 'No listings found',
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
                              adminViewModel.listings.length +
                              (adminViewModel.isLoadingListings ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == adminViewModel.listings.length) {
                              return AdminShimmerWidgets.listingCardShimmer();
                            }

                            final listing = adminViewModel.listings[index];
                            return AdminListingCard(
                              listing: listing,
                              onRemove: () {
                                _showRemoveConfirmation(
                                  context,
                                  listing.title,
                                  () {
                                    adminViewModel.removeListing(listing.id);
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

  void _showRemoveConfirmation(
    BuildContext context,
    String listingTitle,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Listing'),
            content: Text(
              'Are you sure you want to remove "$listingTitle"? '
              'This action will mark the listing as removed and it will no longer be visible to users.',
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
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }
}
