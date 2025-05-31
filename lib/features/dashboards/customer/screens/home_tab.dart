import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/customer_home_viewmodel.dart';
import '../widgets/home_widgets.dart';

class HomeTab extends StatelessWidget {
  final TextEditingController searchController;
  final Function(int) onTabChange;

  const HomeTab({
    super.key,
    required this.searchController,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerHomeViewModel>(
      builder: (context, viewModel, child) {
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => viewModel.refreshAll(),
            child: CustomScrollView(
              slivers: [
                // App Bar with Search
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  snap: true,
                  elevation: 0,
                  backgroundColor: colorScheme.surface,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discover Books',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SearchBar(
                            controller: searchController,
                            hintText: 'Search books, authors, ISBN...',
                            leading: const Icon(Icons.search),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onTap: () {
                              onTabChange(1); // Switch to search tab
                            },
                            onSubmitted: (query) {
                              onTabChange(1); // Switch to search tab
                              viewModel.searchListings(query);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Recently Listed Items Section
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      SectionHeader(
                        title: 'Recently Listed',
                        subtitle: 'Fresh books just added',
                        onSeeAll: () {
                          onTabChange(1); // Switch to search tab
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 260,
                        child:
                            viewModel.isLoadingRecentItems
                                ? _buildLoadingList()
                                : viewModel.recentlyListedItems.isEmpty
                                ? _buildEmptyState(
                                  'No recent books found',
                                  Icons.book_outlined,
                                )
                                : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount:
                                      viewModel.recentlyListedItems.length,
                                  itemBuilder: (context, index) {
                                    final listing =
                                        viewModel.recentlyListedItems[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: ListingCard(listing: listing),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
                // Recently Joined Stores Section
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      SectionHeader(
                        title: 'New Stores',
                        subtitle: 'Recently joined bookstores',
                        onSeeAll: () {
                          onTabChange(2); // Switch to stores tab
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child:
                            viewModel.isLoadingRecentStores
                                ? _buildLoadingList()
                                : viewModel.recentlyJoinedStores.isEmpty
                                ? _buildEmptyState(
                                  'No new stores found',
                                  Icons.store_outlined,
                                )
                                : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount:
                                      viewModel.recentlyJoinedStores.length,
                                  itemBuilder: (context, index) {
                                    final store =
                                        viewModel.recentlyJoinedStores[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: StoreCard(store: store),
                                    );
                                  },
                                ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                // Error Handling
                if (viewModel.errorMessage != null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              viewModel.errorMessage!,
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              viewModel.clearError();
                              viewModel.refreshAll();
                            },
                            child: Text(
                              'Retry',
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
