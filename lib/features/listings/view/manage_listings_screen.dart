import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../model/listing_model.dart';
import '../viewmodel/manage_listings_viewmodel.dart';
import 'add_edit_listing_screen.dart';
import 'listing_details_screen.dart';

class ManageListingsScreen extends StatefulWidget {
  const ManageListingsScreen({super.key});

  @override
  State<ManageListingsScreen> createState() => _ManageListingsScreenState();
}

class _ManageListingsScreenState extends State<ManageListingsScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<ManageListingsViewModel>(
        context,
        listen: false,
      );
      if (viewModel.listings.isEmpty && !viewModel.isLoading) {
        debugPrint('🔧 ManageListingsScreen: Loading listings...');
        viewModel.loadListings();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final viewModel = Provider.of<ManageListingsViewModel>(
        context,
        listen: false,
      );
      viewModel.handleAppLifecycleResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ManageListingsViewModel>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddListing(viewModel),
        icon: const Icon(Icons.add),
        label: const Text('New Listing'),
      ),
      body: Column(
        children: [
          _buildHeader(context, viewModel, colorScheme),
          Expanded(
            child: _buildListingsContent(context, viewModel, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ManageListingsViewModel viewModel,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 16,
        16,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Listings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SearchBar(
            controller: _searchController,
            hintText: 'Search listings',
            leading: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            trailing: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear();
                    viewModel.clearSearchTerm();
                  },
                ),
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                },
              ),
            ],
            onChanged: viewModel.updateSearchTerm,
          ),
        ],
      ),
    );
  }

  Widget _buildListingsContent(
    BuildContext context,
    ManageListingsViewModel viewModel,
    ColorScheme colorScheme,
  ) {
    return RefreshIndicator(
      onRefresh: viewModel.refreshListings,
      child: Consumer<ManageListingsViewModel>(
        builder: (context, vm, child) {
          if (vm.shouldShowLoadingState) {
            return _buildLoadingState();
          }

          if (vm.shouldShowErrorState) {
            return _buildErrorState(
              context,
              vm.errorMessage ?? 'Unknown error',
              vm,
              colorScheme,
            );
          }

          final listings = vm.filteredListings;
          if (listings.isEmpty) {
            return _buildEmptyState(context, vm, colorScheme);
          }

          return _buildListingsGrid(context, listings, vm, colorScheme);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      children: const [
        SizedBox(height: 200),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String error,
    ManageListingsViewModel viewModel,
    ColorScheme colorScheme,
  ) {
    return ListView(
      children: [
        const SizedBox(height: 200),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Error: $error', style: TextStyle(color: colorScheme.error)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: viewModel.refreshListings,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ManageListingsViewModel viewModel,
    ColorScheme colorScheme,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 200),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Listings Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh or add your first listing',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _navigateToAddListing(viewModel),
                icon: const Icon(Icons.add),
                label: const Text('Add New Listing'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListingsGrid(
    BuildContext context,
    List<Listing> listings,
    ManageListingsViewModel viewModel,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        return _buildListingCard(context, listing, viewModel, colorScheme);
      },
    );
  }

  Widget _buildListingCard(
    BuildContext context,
    Listing listing,
    ManageListingsViewModel viewModel,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress:
            () => _showListingOptionsBottomSheet(
              context,
              listing,
              viewModel,
              colorScheme,
            ),
        onTap: () => _navigateToListingDetails(listing),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildListingImage(listing, colorScheme),
              const SizedBox(width: 16),
              Expanded(child: _buildListingDetails(listing, colorScheme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListingImage(Listing listing, ColorScheme colorScheme) {
    return Hero(
      tag: 'listing-${listing.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          listing.coverUrl,
          width: 80,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 80,
              height: 100,
              color: colorScheme.surfaceVariant,
              child: Icon(
                Icons.image_not_supported_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListingDetails(Listing listing, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                listing.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '#${listing.id}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'by ${listing.author}',
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    listing.condition == 'new'
                        ? colorScheme.primaryContainer
                        : colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                listing.condition.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color:
                      listing.condition == 'new'
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onTertiaryContainer,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '\$${listing.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showListingOptionsBottomSheet(
    BuildContext context,
    Listing listing,
    ManageListingsViewModel viewModel,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (bottomSheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit Listing'),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await _navigateToEditListing(viewModel, listing);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: colorScheme.error),
                  title: Text(
                    'Delete Listing',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await _handleDeleteListing(context, listing, viewModel);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  Future<void> _navigateToAddListing(ManageListingsViewModel viewModel) async {
    await viewModel.handleAddListingNavigation();
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditListingScreen()),
    );

    if (mounted) {
      await viewModel.handleNavigationResult(result);
    }
  }

  Future<void> _navigateToEditListing(
    ManageListingsViewModel viewModel,
    Listing listing,
  ) async {
    await viewModel.handleAddListingNavigation();
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditListingScreen(listing: listing),
      ),
    );

    if (mounted) {
      await viewModel.handleNavigationResult(result);
    }
  }

  void _navigateToListingDetails(Listing listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListingDetailsScreen(listing: listing),
      ),
    );
  }

  Future<void> _handleDeleteListing(
    BuildContext context,
    Listing listing,
    ManageListingsViewModel viewModel,
  ) async {
    final shouldDelete = await viewModel.showDeleteConfirmation(
      context: context,
      listingTitle: listing.title,
    );

    if (shouldDelete && mounted) {
      await viewModel.handleDeleteListing(
        listingId: listing.id!,
        listingTitle: listing.title,
        scaffoldMessenger: ScaffoldMessenger.of(context),
      );
    }
  }
}
