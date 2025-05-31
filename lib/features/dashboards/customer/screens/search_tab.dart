import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/customer_home_viewmodel.dart';
import '../widgets/home_widgets.dart';

class SearchTab extends StatelessWidget {
  final TextEditingController searchController;

  const SearchTab({super.key, required this.searchController});

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerHomeViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Search Books'),
            centerTitle: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SearchBar(
                  controller: searchController,
                  hintText: 'Search books, authors, ISBN...',
                  leading: const Icon(Icons.search),
                  onSubmitted: (query) => viewModel.searchListings(query),
                  onChanged: (query) {
                    if (query.isEmpty) {
                      viewModel.clearSearch();
                    }
                  },
                ),
              ),
            ),
          ),
          body:
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
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.6,
                        ),
                    itemCount: viewModel.searchResults.length,
                    itemBuilder: (context, index) {
                      final listing = viewModel.searchResults[index];
                      return ListingCard(listing: listing);
                    },
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
