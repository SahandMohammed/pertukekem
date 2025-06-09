import 'package:flutter/material.dart';
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

class _ManageListingsScreenState extends State<ManageListingsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ManageListingsViewModel>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditListingScreen(),
            ),
          ); // Explicitly refresh listings when returning from add screen
          await Provider.of<ManageListingsViewModel>(
            context,
            listen: false,
          ).refreshListings();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Listing'),
      ),
      body: Column(
        children: [
          // Title and Search bar
          Padding(
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
                  leading: Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          viewModel.updateSearchTerm('');
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        // TODO: Implement filtering
                      },
                    ),
                  ],
                  onChanged: (value) {
                    viewModel.updateSearchTerm(value);
                  },
                ),
              ],
            ),
          ),
          // Listings content
          Expanded(
            child: StreamBuilder<List<Listing>>(
              stream: viewModel.sellerListingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    viewModel.isRefreshing) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: colorScheme.error),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () async {
                            await viewModel.refreshListings();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final listings = snapshot.data ?? [];
                if (listings.isEmpty) {
                  return Center(
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
                          'Add your first listing by tapping the button below',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const AddEditListingScreen(),
                              ),
                            ); // Refresh listings when returning from add screen (empty state case)
                            await Provider.of<ManageListingsViewModel>(
                              context,
                              listen: false,
                            ).refreshListings();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Listing'),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    await viewModel.refreshListings();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: listings.length,
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onLongPress: () {
                            // Get scaffold messenger context
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );

                            showModalBottomSheet(
                              context: context,
                              builder:
                                  (bottomSheetContext) => SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(
                                            Icons.edit_outlined,
                                          ),
                                          title: const Text('Edit Listing'),
                                          onTap: () async {
                                            Navigator.pop(
                                              bottomSheetContext,
                                            ); // Close bottom sheet
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        AddEditListingScreen(
                                                          listing: listing,
                                                        ),
                                              ),
                                            ); // Refresh listings when returning from edit screen
                                            await Provider.of<
                                              ManageListingsViewModel
                                            >(
                                              context,
                                              listen: false,
                                            ).refreshListings();
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.delete_outline,
                                            color: colorScheme.error,
                                          ),
                                          title: Text(
                                            'Delete Listing',
                                            style: TextStyle(
                                              color: colorScheme.error,
                                            ),
                                          ),
                                          onTap: () async {
                                            // Get viewModel reference before pop
                                            final vm = Provider.of<
                                              ManageListingsViewModel
                                            >(context, listen: false);
                                            Navigator.pop(
                                              bottomSheetContext,
                                            ); // Close bottom sheet

                                            // Show confirmation dialog
                                            final shouldDelete = await showDialog<
                                              bool
                                            >(
                                              context: context,
                                              builder:
                                                  (
                                                    dialogContext,
                                                  ) => AlertDialog(
                                                    title: const Text(
                                                      'Delete Listing',
                                                    ),
                                                    content: Text(
                                                      'Are you sure you want to delete "${listing.title}"?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              dialogContext,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              dialogContext,
                                                              true,
                                                            ),
                                                        style:
                                                            TextButton.styleFrom(
                                                              foregroundColor:
                                                                  Colors.red,
                                                            ),
                                                        child: const Text(
                                                          'Delete',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );

                                            // If user confirmed deletion
                                            if (shouldDelete == true) {
                                              try {
                                                await vm.deleteListing(
                                                  listing.id!,
                                                );
                                                scaffoldMessenger.showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Listing deleted successfully',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              } catch (e) {
                                                scaffoldMessenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error deleting listing: $e',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                        // Add padding at the bottom for better visual appearance
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                            );
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        ListingDetailsScreen(listing: listing),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cover Image
                                Hero(
                                  tag: 'listing-${listing.id}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      listing.coverUrl,
                                      width: 80,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
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
                                ),
                                const SizedBox(width: 16),
                                // Listing Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'by ${listing.author}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  listing.condition == 'new'
                                                      ? colorScheme
                                                          .primaryContainer
                                                      : colorScheme
                                                          .tertiaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              listing.condition.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    listing.condition == 'new'
                                                        ? colorScheme
                                                            .onPrimaryContainer
                                                        : colorScheme
                                                            .onTertiaryContainer,
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
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
