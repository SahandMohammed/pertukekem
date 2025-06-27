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
  String? _selectedCondition; // 'new', 'used', or null for all

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
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(
                        const Duration(milliseconds: 300),
                        () {
                          viewModel.searchListings(
                            query,
                            condition: _selectedCondition,
                          );
                          if (_selectedCategory != null) {
                            setState(() {
                              _selectedCategory = null;
                            });
                          }
                        },
                      );
                    }
                  },
                  trailing: [
                    IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.tune),
                          if (_selectedCategory != null ||
                              _selectedCondition != null)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: _showFilterBottomSheet,
                      tooltip: 'Filters',
                    ),
                  ],
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
                    : viewModel.searchResults.isEmpty &&
                        _selectedCategory != null
                    ? _buildEmptyState(
                      'No books found in "$_selectedCategory" category',
                      Icons.category_outlined,
                    )
                    : viewModel.searchResults.isEmpty
                    ? _buildEmptyState(
                      _selectedCondition != null
                          ? 'Enter a search term or select a category to find ${_selectedCondition} books'
                          : 'Enter a search term or select a category to find books',
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter Books',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedCategory = null;
                                _selectedCondition = null;
                              });
                              setState(() {
                                _selectedCategory = null;
                                _selectedCondition = null;
                              });
                              _applyFilters();
                            },
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildBottomSheetCategorySection(setModalState),
                      const SizedBox(height: 24),

                      _buildBottomSheetConditionSection(setModalState),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Apply Filters'),
                        ),
                      ),

                      SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildBottomSheetCategorySection(StateSetter setModalState) {
    return Column(
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
              'Category',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
                    setModalState(() {
                      _selectedCategory = selected ? category : null;
                    });
                    setState(() {
                      _selectedCategory = selected ? category : null;
                    });
                  },
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
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
    );
  }

  Widget _buildBottomSheetConditionSection(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.filter_list_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Condition',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildBottomSheetConditionChip('All', null, setModalState),
            const SizedBox(width: 8),
            _buildBottomSheetConditionChip('New', 'new', setModalState),
            const SizedBox(width: 8),
            _buildBottomSheetConditionChip('Used', 'used', setModalState),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomSheetConditionChip(
    String label,
    String? condition,
    StateSetter setModalState,
  ) {
    final isSelected = _selectedCondition == condition;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          _selectedCondition = condition;
        });
        setState(() {
          _selectedCondition = condition;
        });
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color:
            isSelected
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color:
            isSelected
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.outline.withOpacity(0.5),
      ),
      showCheckmark: false,
    );
  }

  void _applyFilters() {
    final viewModel = Provider.of<CustomerHomeViewModel>(
      context,
      listen: false,
    );

    if (_selectedCategory != null) {
      widget.searchController.clear();
      viewModel.searchListings(
        _selectedCategory!,
        condition: _selectedCondition,
      );
    } else if (viewModel.searchQuery.isNotEmpty) {
      viewModel.searchListings(
        viewModel.searchQuery,
        condition: _selectedCondition,
      );
    } else {
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
