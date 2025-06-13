import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/customer_home_viewmodel.dart';
import '../widgets/home_widgets.dart';

class SearchTab extends StatefulWidget {
  final TextEditingController searchController;

  const SearchTab({super.key, required this.searchController});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerHomeViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Search Books'),
            centerTitle: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SearchBar(
                  controller: widget.searchController,
                  hintText: 'Search books, authors, ISBN...',
                  leading: const Icon(Icons.search),
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.surface,
                  ),
                  elevation: WidgetStateProperty.all(2),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (query) {
                    if (query.isEmpty) {
                      viewModel.clearSearch();
                    } else {
                      // Cancel previous timer if it exists
                      _debounceTimer?.cancel();
                      // Start a new timer
                      _debounceTimer = Timer(
                        const Duration(milliseconds: 300),
                        () {
                          viewModel.searchListings(query);
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                viewModel.isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : viewModel.searchResults.isEmpty &&
                        viewModel.searchQuery.isNotEmpty
                    ? _buildEmptyState(
                      'No books found for "${viewModel.searchQuery}"',
                      Icons.search_off,
                    )
                    : viewModel.searchResults.isEmpty
                    ? _buildEmptyState(
                      'Enter a search term to find books',
                      Icons.search,
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: viewModel.searchResults.length,
                      itemBuilder: (context, index) {
                        final listing = viewModel.searchResults[index];
                        return ListingCard(listing: listing);
                      },
                    ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              icon == Icons.search_off
                  ? 'Try adjusting your search terms or browse our featured books.'
                  : 'Discover thousands of books from verified sellers.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
