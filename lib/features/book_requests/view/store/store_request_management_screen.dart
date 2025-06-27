import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/book_request_viewmodel.dart';
import '../../model/book_request_model.dart';

class StoreRequestManagementScreen extends StatefulWidget {
  const StoreRequestManagementScreen({super.key});

  @override
  State<StoreRequestManagementScreen> createState() =>
      _StoreRequestManagementScreenState();
}

class _StoreRequestManagementScreenState
    extends State<StoreRequestManagementScreen> {
  BookRequestStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookRequestViewModel>().loadStoreRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Requests'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<BookRequestViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.pendingRequestsCount > 0) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          setState(() {
                            _selectedStatus = BookRequestStatus.pending;
                          });
                        },
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${viewModel.pendingRequestsCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BookRequestViewModel>().loadStoreRequests();
            },
          ),
        ],
      ),
      body: Consumer<BookRequestViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.storeRequests.isEmpty) {
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
                      viewModel.loadStoreRequests();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final filteredRequests = _selectedStatus == null
              ? viewModel.storeRequests
              : viewModel.getRequestsByStatus(
                  viewModel.storeRequests,
                  _selectedStatus,
                );

          if (viewModel.storeRequests.isEmpty) {
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
                        onRefresh: () => viewModel.loadStoreRequests(),
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
            label: Text('All (${viewModel.storeRequests.length})'),
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
              viewModel.storeRequests,
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
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Requested by ${request.customerName}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
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
                      'Customer Note:',
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
                      'Your Response:',
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
                const Spacer(),
                if (request.status == BookRequestStatus.pending) ...[
                  TextButton(
                    onPressed: () => _showResponseDialog(
                      request,
                      BookRequestStatus.rejected,
                      viewModel,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _showResponseDialog(
                      request,
                      BookRequestStatus.accepted,
                      viewModel,
                    ),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Accept'),
                  ),
                ],
                if (request.status == BookRequestStatus.accepted)
                  FilledButton(
                    onPressed: () => _showResponseDialog(
                      request,
                      BookRequestStatus.fulfilled,
                      viewModel,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Mark Fulfilled'),
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
                Icons.inbox_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Book Requests',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No customers have requested books from your store yet. Book requests will appear here when customers submit them.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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

  Future<void> _showResponseDialog(
    BookRequest request,
    BookRequestStatus newStatus,
    BookRequestViewModel viewModel,
  ) async {
    String? response;
    final responseController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newStatus.name.capitalize()} Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book: "${request.bookTitle}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Customer: ${request.customerName}'),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              decoration: InputDecoration(
                labelText: 'Response Message ${newStatus == BookRequestStatus.rejected ? '(Required)' : '(Optional)'}',
                hintText: newStatus == BookRequestStatus.accepted
                    ? 'Book is available. Price: \$XX.XX'
                    : newStatus == BookRequestStatus.fulfilled
                        ? 'Book has been fulfilled and is ready for pickup/delivery'
                        : 'Unfortunately, this book is not available',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (newStatus == BookRequestStatus.rejected &&
                  responseController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Response message is required for rejection'),
                  ),
                );
                return;
              }
              response = responseController.text.trim();
              Navigator.of(context).pop(true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: newStatus == BookRequestStatus.rejected
                  ? Colors.red
                  : newStatus == BookRequestStatus.fulfilled
                      ? Colors.green
                      : null,
            ),
            child: Text(newStatus.name.capitalize()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await viewModel.respondToRequest(
        requestId: request.id,
        status: newStatus,
        response: response?.isNotEmpty == true ? response : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${newStatus.name} successfully'),
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
