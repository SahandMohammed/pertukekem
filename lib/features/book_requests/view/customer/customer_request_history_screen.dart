import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/book_request_viewmodel.dart';
import '../../model/book_request_model.dart';
import 'request_book_screen.dart';

class CustomerRequestHistoryScreen extends StatefulWidget {
  const CustomerRequestHistoryScreen({super.key});

  @override
  State<CustomerRequestHistoryScreen> createState() =>
      _CustomerRequestHistoryScreenState();
}

class _CustomerRequestHistoryScreenState
    extends State<CustomerRequestHistoryScreen> {
  BookRequestStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookRequestViewModel>().loadCustomerRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Book Requests'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BookRequestViewModel>().loadCustomerRequests();
            },
          ),
        ],
      ),
      body: Consumer<BookRequestViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.customerRequests.isEmpty) {
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
                    'Error Loading Requests',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.error!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.loadCustomerRequests();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final filteredRequests = _selectedStatus == null
              ? viewModel.customerRequests
              : viewModel.getRequestsByStatus(
                  viewModel.customerRequests,
                  _selectedStatus,
                );

          if (viewModel.customerRequests.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Filter Chips
              _buildFilterChips(viewModel),
              
              // Requests List
              Expanded(
                child: filteredRequests.isEmpty
                    ? _buildNoResultsState()
                    : RefreshIndicator(
                        onRefresh: () => viewModel.loadCustomerRequests(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredRequests.length,
                          itemBuilder: (context, index) {
                            return _buildRequestCard(
                              filteredRequests[index],
                              viewModel,
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider.value(
                value: context.read<BookRequestViewModel>(),
                child: const RequestBookScreen(),
              ),
            ),
          );

          if (result == true && mounted) {
            context.read<BookRequestViewModel>().loadCustomerRequests();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Request Book'),
      ),
    );
  }

  Widget _buildFilterChips(BookRequestViewModel viewModel) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: Text('All (${viewModel.customerRequests.length})'),
            selected: _selectedStatus == null,
            onSelected: (selected) {
              setState(() {
                _selectedStatus = selected ? null : _selectedStatus;
              });
            },
          ),
          const SizedBox(width: 8),
          ...BookRequestStatus.values.map((status) {
            final count = viewModel.getRequestsByStatus(
              viewModel.customerRequests,
              status,
            ).length;
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('${status.name.capitalize()} ($count)'),
                selected: _selectedStatus == status,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = selected ? status : null;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BookRequest request, BookRequestViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color getStatusColor(BookRequestStatus status) {
      switch (status) {
        case BookRequestStatus.pending:
          return Colors.orange;
        case BookRequestStatus.accepted:
          return Colors.blue;
        case BookRequestStatus.rejected:
          return Colors.red;
        case BookRequestStatus.fulfilled:
          return Colors.green;
        case BookRequestStatus.cancelled:
          return Colors.grey;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with book title and status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.bookTitle,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.storeName,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: getStatusColor(request.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: getStatusColor(request.status).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    request.statusDisplayText,
                    style: textTheme.bodySmall?.copyWith(
                      color: getStatusColor(request.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            if (request.note != null && request.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Note:',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.note!,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],

            if (request.storeResponse != null &&
                request.storeResponse!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Store Response:',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.storeResponse!,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Footer with date and actions
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(request.createdAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (request.responseDate != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.reply,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Responded ${_formatDate(request.responseDate!)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const Spacer(),
                if (request.canBeCancelled)
                  TextButton(
                    onPressed: () => _showCancelDialog(request, viewModel),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.book_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Book Requests Yet',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t requested any books yet. Start by requesting a book from your favorite store!',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: context.read<BookRequestViewModel>(),
                      child: const RequestBookScreen(),
                    ),
                  ),
                );

                if (result == true && mounted) {
                  context.read<BookRequestViewModel>().loadCustomerRequests();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Request Your First Book'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No requests found for the selected filter.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedStatus = null;
                });
              },
              child: const Text('Clear Filter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(
    BookRequest request,
    BookRequestViewModel viewModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: Text(
          'Are you sure you want to cancel your request for "${request.bookTitle}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Request'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await viewModel.cancelRequest(request.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request cancelled successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

extension StringCapitalizeExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
