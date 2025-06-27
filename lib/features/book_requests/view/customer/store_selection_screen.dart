import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/book_request_viewmodel.dart';
import '../../../dashboards/model/store_model.dart';

class StoreSelectionScreen extends StatefulWidget {
  final StoreModel? initialSelection;

  const StoreSelectionScreen({
    super.key,
    this.initialSelection,
  });

  @override
  State<StoreSelectionScreen> createState() => _StoreSelectionScreenState();
}

class _StoreSelectionScreenState extends State<StoreSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<StoreModel> _filteredStores = [];
  StoreModel? _selectedStore;

  @override
  void initState() {
    super.initState();
    _selectedStore = widget.initialSelection;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookRequestViewModel>().loadAvailableStores();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStores(String query, List<StoreModel> allStores) {
    setState(() {
      if (query.isEmpty) {
        _filteredStores = allStores;
      } else {
        _filteredStores = allStores.where((store) {
          return store.storeName.toLowerCase().contains(query.toLowerCase()) ||
              (store.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Store'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_selectedStore != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_selectedStore);
              },
              child: const Text('Done'),
            ),
        ],
      ),
      body: Consumer<BookRequestViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.availableStores.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading stores',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.error!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.loadAvailableStores();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.availableStores.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 64,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No stores available',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'There are currently no stores to request books from.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Initialize filtered stores if not already done
          if (_filteredStores.isEmpty && _searchController.text.isEmpty) {
            _filteredStores = viewModel.availableStores;
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search stores...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterStores('', viewModel.availableStores);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    _filterStores(value, viewModel.availableStores);
                  },
                ),
              ),

              // Results count
              if (_searchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${_filteredStores.length} store${_filteredStores.length != 1 ? 's' : ''} found',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Store List
              Expanded(
                child: _filteredStores.isEmpty && _searchController.text.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No stores found',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredStores.length,
                        itemBuilder: (context, index) {
                          final store = _filteredStores[index];
                          final isSelected = _selectedStore?.storeId == store.storeId;

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline.withOpacity(0.1),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primary.withOpacity(0.1)
                                      : colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(24),
                                  border: isSelected
                                      ? Border.all(
                                          color: colorScheme.primary,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: store.logoUrl != null && store.logoUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(22),
                                        child: Image.network(
                                          store.logoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stack) => Icon(
                                            Icons.store,
                                            color: isSelected
                                                ? colorScheme.primary
                                                : colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.store,
                                        color: isSelected
                                            ? colorScheme.primary
                                            : colorScheme.onPrimaryContainer,
                                      ),
                              ),
                              title: Text(
                                store.storeName,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? colorScheme.primary : null,
                                ),
                              ),
                              subtitle: store.description != null && store.description!.isNotEmpty
                                  ? Text(
                                      store.description!,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: colorScheme.primary,
                                    )
                                  : Icon(
                                      Icons.circle_outlined,
                                      color: colorScheme.outline,
                                    ),
                              onTap: () {
                                setState(() {
                                  _selectedStore = store;
                                });
                                // Auto-return after short delay for better UX
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (mounted) {
                                    Navigator.of(context).pop(store);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
