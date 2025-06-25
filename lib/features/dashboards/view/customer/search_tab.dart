import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/customer_home_viewmodel.dart';
import '../../widgets/home_widgets.dart';

class SearchTab extends StatefulWidget {
  final TextEditingController searchController;

  const SearchTab({super.key, required this.searchController});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  Timer? _debounceTimer;
  String? _selectedCategory;

  // Popular book categories for quick access
  final List<String> _popularCategories = [
    'Fiction',
    'Non-Fiction',
    'Science',
    'Biography',
    'History',
    'Romance',
    'Mystery',
    'Fantasy',
    'Self-Help',
    'Business',
    'Technology',
    'Health',
    'Children',
    'Education',
    'Art',
  ];

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
                  hintText: 'Search books, authors, categories, ISBN...',
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
                      setState(() {
                        _selectedCategory = null;
                      });
                    } else {
                      // Cancel previous timer if it exists
                      _debounceTimer?.cancel();
                      // Start a new timer
                      _debounceTimer = Timer(
                        const Duration(milliseconds: 300),
                        () {
                          viewModel.searchListings(query);
                          // Clear category selection when searching by text
                          if (_selectedCategory != null) {
                            setState(() {
                              _selectedCategory = null;
                            });
                          }
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Category Filter Section
              if (widget.searchController.text.isEmpty) _buildCategoryFilter(),

              // Search Results
              Expanded(
                child: Padding(
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
                          : viewModel.searchResults.isEmpty &&
                              _selectedCategory != null
                          ? _buildEmptyState(
                            'No books found in "$_selectedCategory" category',
                            Icons.category_outlined,
                          )
                          : viewModel.searchResults.isEmpty
                          ? _buildEmptyState(
                            'Enter a search term or select a category to find books',
                            Icons.search,
                          )
                          : GridView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      MediaQuery.of(context).size.width > 600
                                          ? 3
                                          : 2,
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Browse by Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _popularCategories.length,
              itemBuilder: (context, index) {
                final category = _popularCategories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: EdgeInsets.only(right: 8, left: index == 0 ? 0 : 0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      _onCategorySelected(selected ? category : null);
                    },
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.5),
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });

    if (category != null) {
      // Clear the search controller text when selecting a category
      widget.searchController.clear();

      // Search by category
      final viewModel = Provider.of<CustomerHomeViewModel>(
        context,
        listen: false,
      );
      viewModel.searchListings(category);
    } else {
      // Clear search when no category is selected
      final viewModel = Provider.of<CustomerHomeViewModel>(
        context,
        listen: false,
      );
      viewModel.clearSearch();
    }
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
                  ? 'Try adjusting your search terms, browse by category, or explore our featured books.'
                  : icon == Icons.category_outlined
                  ? 'Try selecting a different category or search by book title instead.'
                  : 'Discover thousands of books from verified sellers by searching or browsing categories.',
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
