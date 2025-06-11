import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../model/order_model.dart';
import '../viewmodel/order_viewmodel.dart';
import '../../listings/model/listing_model.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildOrderSummaryCard(context),
                const SizedBox(height: 20),
                _buildBookDetailsCard(context),
                const SizedBox(height: 20),
                _buildCustomerInfoCard(context),
                const SizedBox(height: 20),
                if (order.shippingAddress != null) _buildShippingCard(context),
                if (order.shippingAddress != null) const SizedBox(height: 20),
                if (order.trackingNumber != null) _buildTrackingCard(context),
                if (order.trackingNumber != null) const SizedBox(height: 20),
                _buildStatusTimelineCard(context),
                const SizedBox(height: 20),
                _buildActionButtons(context),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SliverAppBar(
      toolbarHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: colorScheme.onSurfaceVariant,
            size: 16,
          ),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getStatusIcon(order.status),
                color: _getStatusColor(order.status),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8).toUpperCase()}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _getStatusText(order.status),
                    style: textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Consumer<OrderViewModel>(
          builder: (context, viewModel, child) {
            return PopupMenuButton<OrderStatus>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.more_vert,
                  color: colorScheme.onPrimaryContainer,
                  size: 18,
                ),
              ),
              onSelected: (newStatus) {
                _updateOrderStatus(context, newStatus, viewModel);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) {
                return OrderStatus.values
                    .where((status) => status != order.status)
                    .map(
                      (status) => PopupMenuItem(
                        value: status,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStatusColor(status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('Mark as ${_getStatusText(status)}'),
                          ],
                        ),
                      ),
                    )
                    .toList();
              },
            );
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Order Summary',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Order Date',
                    DateFormat(
                      'MMM dd, yyyy • hh:mm a',
                    ).format(order.createdAt.toDate()),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Quantity',
                    '${order.quantity} item${order.quantity > 1 ? 's' : ''}',
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Total Amount',
                    '\$${NumberFormat('#,##0.00').format(order.totalAmount)}',
                    isHighlighted: true,
                  ),
                  if (order.updatedAt != null) ...[
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Last Updated',
                      DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      ).format(order.updatedAt!.toDate()),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 16 : 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            color: isHighlighted ? Colors.green[700] : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBookDetailsCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.menu_book_outlined,
                    color: colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Book Details',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<Listing?>(
              future: _fetchBookDetails(order.listingRef.id),
              builder: (context, snapshot) {
                print('📱 FutureBuilder state: ${snapshot.connectionState}');
                print('📱 Has error: ${snapshot.hasError}');
                print('📱 Has data: ${snapshot.hasData}');
                if (snapshot.hasError) {
                  print('📱 Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Could not load book details',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Listing ID: ${order.listingRef.id}',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (snapshot.hasError)
                          Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  );
                }

                final book = snapshot.data!;
                return _buildBookInfo(context, book);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookInfo(BuildContext context, Listing book) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Image
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.surfaceContainerHighest,
                ),
                child:
                    book.coverUrl.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            book.coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.book_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 32,
                                ),
                              );
                            },
                          ),
                        )
                        : Icon(
                          Icons.book_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 32,
                        ),
              ),
              const SizedBox(width: 16),
              // Book Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${book.author}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          book.category.isNotEmpty
                              ? book.category.first
                              : 'general',
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        book.category.isNotEmpty
                            ? book.category.first
                            : 'General',
                        style: textTheme.labelSmall?.copyWith(
                          color: _getCategoryColor(
                            book.category.isNotEmpty
                                ? book.category.first
                                : 'general',
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Book Details Grid
          Column(
            children: [
              _buildBookDetailRow('ISBN', book.isbn),
              const SizedBox(height: 8),
              _buildBookDetailRow('Condition', book.condition),
              const SizedBox(height: 8),
              _buildBookDetailRow(
                'Price per item',
                '\$${NumberFormat('#,##0.00').format(book.price)}',
              ),
              const SizedBox(height: 8),
              _buildBookDetailRow(
                'Publication Year',
                book.year?.toString() ?? 'Not available',
              ),
              if (book.description?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  'Description',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.description!,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: colorScheme.onTertiaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Customer Information',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildCustomerDetailRow(
                    'Customer ID',
                    order.buyerRef.id.substring(0, 8).toUpperCase(),
                  ),
                  const SizedBox(height: 8),
                  _buildCustomerDetailRow(
                    'Order Date',
                    DateFormat(
                      'EEEE, MMM dd, yyyy',
                    ).format(order.createdAt.toDate()),
                  ),
                  const SizedBox(height: 8),
                  _buildCustomerDetailRow(
                    'Order Time',
                    DateFormat('hh:mm a').format(order.createdAt.toDate()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildShippingCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Shipping Address',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                order.shippingAddress!,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.blue.shade900,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Tracking Information',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tracking Number',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.trackingNumber!,
                          style: textTheme.bodyLarge?.copyWith(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyTrackingNumber(context),
                    icon: Icon(
                      Icons.copy_rounded,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimelineCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final statusSteps = [
      {
        'status': OrderStatus.pending,
        'title': 'Order Received',
        'subtitle': 'Order placed by customer',
      },
      {
        'status': OrderStatus.confirmed,
        'title': 'Order Confirmed',
        'subtitle': 'Ready for processing',
      },
      {
        'status': OrderStatus.shipped,
        'title': 'Order Shipped',
        'subtitle': 'Package is on the way',
      },
      {
        'status': OrderStatus.delivered,
        'title': 'Order Delivered',
        'subtitle': 'Successfully delivered',
      },
    ];

    final currentStatusIndex = statusSteps.indexWhere(
      (step) => step['status'] == order.status,
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.timeline_outlined,
                    color: Colors.purple.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Order Timeline',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              children:
                  statusSteps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    final status = step['status'] as OrderStatus;
                    final isCompleted = index <= currentStatusIndex;
                    final isCurrent = index == currentStatusIndex;
                    final isLast = index == statusSteps.length - 1;

                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color:
                                        isCompleted
                                            ? _getStatusColor(status)
                                            : colorScheme.outline.withOpacity(
                                              0.3,
                                            ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCompleted
                                        ? (isCurrent
                                            ? _getStatusIcon(status)
                                            : Icons.check)
                                        : Icons.radio_button_unchecked,
                                    color:
                                        isCompleted
                                            ? Colors.white
                                            : colorScheme.outline,
                                    size: 16,
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 40,
                                    color:
                                        isCompleted
                                            ? _getStatusColor(
                                              status,
                                            ).withOpacity(0.3)
                                            : colorScheme.outline.withOpacity(
                                              0.2,
                                            ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step['title'] as String,
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight:
                                          isCompleted
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                      color:
                                          isCompleted
                                              ? colorScheme.onSurface
                                              : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    step['subtitle'] as String,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!isLast) const SizedBox(height: 8),
                      ],
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer<OrderViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            if (order.status == OrderStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          () => _updateOrderStatus(
                            context,
                            OrderStatus.confirmed,
                            viewModel,
                          ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirm Order'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          () => _updateOrderStatus(
                            context,
                            OrderStatus.rejected,
                            viewModel,
                          ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Reject Order'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (order.status == OrderStatus.confirmed) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showShipOrderDialog(context, viewModel),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Mark as Shipped'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            if (order.status == OrderStatus.shipped) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      () => _updateOrderStatus(
                        context,
                        OrderStatus.delivered,
                        viewModel,
                      ),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Mark as Delivered'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactCustomer(context),
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('Contact Customer'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _printOrderDetails(context),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<Listing?> _fetchBookDetails(String listingId) async {
    try {
      print('🔍 Fetching book details for listing ID: $listingId');

      final doc =
          await firestore.FirebaseFirestore.instance
              .collection('listings')
              .doc(listingId)
              .get();

      print('📄 Document exists: ${doc.exists}');

      if (doc.exists) {
        final data = doc.data();
        print('✅ Found listing data: $data');

        // Check if essential fields are present and provide defaults for missing ones
        if (data != null) {
          // Log specific field availability
          print('📝 Field availability check:');
          print('  - title: ${data['title']}');
          print('  - author: ${data['author']}');
          print('  - sellerRef: ${data['sellerRef']}');
          print('  - description: ${data['description']}');
          print('  - isbn: ${data['isbn']}');
          print('  - price: ${data['price']}');
          print('  - coverUrl: ${data['coverUrl']}');

          // Ensure required fields have defaults if missing
          final Map<String, dynamic> processedData = Map.from(data);

          // Add missing required fields with defaults
          if (processedData['author'] == null) {
            processedData['author'] = 'Unknown Author';
            print('⚠️ Missing author field, using default: "Unknown Author"');
          }

          if (processedData['condition'] == null) {
            processedData['condition'] = 'used';
            print('⚠️ Missing condition field, using default: "used"');
          }

          if (processedData['category'] == null) {
            processedData['category'] = ['General'];
            print('⚠️ Missing category field, using default: ["General"]');
          }

          if (processedData['isbn'] == null) {
            processedData['isbn'] = '';
            print('⚠️ Missing isbn field, using default: ""');
          }

          if (processedData['coverUrl'] == null) {
            processedData['coverUrl'] = '';
            print('⚠️ Missing coverUrl field, using default: ""');
          }

          if (processedData['bookType'] == null) {
            processedData['bookType'] = 'physical';
            print('⚠️ Missing bookType field, using default: "physical"');
          } // Manually create a Listing object with safe data
          return Listing(
            id: doc.id,
            sellerRef:
                processedData['sellerRef'] as firestore.DocumentReference,
            sellerType: processedData['sellerType'] as String,
            title: processedData['title'] as String,
            author: processedData['author'] as String,
            condition: processedData['condition'] as String,
            price: (processedData['price'] as num).toDouble(),
            category: List<String>.from(
              processedData['category'] as List<dynamic>,
            ),
            isbn: processedData['isbn'] as String,
            coverUrl: processedData['coverUrl'] as String,
            description: processedData['description'] as String?,
            publisher: processedData['publisher'] as String?,
            language: processedData['language'] as String?,
            pageCount:
                processedData['pageCount'] != null
                    ? (processedData['pageCount'] as num).toInt()
                    : null,
            year:
                processedData['year'] != null
                    ? (processedData['year'] as num).toInt()
                    : null,
            format: processedData['format'] as String?,
            bookType: processedData['bookType'] as String,
            ebookUrl: processedData['ebookUrl'] as String?,
            createdAt: processedData['createdAt'] as firestore.Timestamp?,
            updatedAt: processedData['updatedAt'] as firestore.Timestamp?,
          );
        } else {
          print('❌ Document data is null');
          return null;
        }
      } else {
        print('❌ No document found for listing ID: $listingId');
        return null;
      }
    } catch (e, stackTrace) {
      print('💥 Error fetching book details: $e');
      print('📚 Stack trace: $stackTrace');
      return null;
    }
  }

  void _updateOrderStatus(
    BuildContext context,
    OrderStatus newStatus,
    OrderViewModel viewModel,
  ) {
    viewModel.updateOrderStatus(order.id, newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order status updated to ${_getStatusText(newStatus)}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showShipOrderDialog(BuildContext context, OrderViewModel viewModel) {
    final trackingController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Ship Order'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter tracking number (optional):'),
                const SizedBox(height: 16),
                TextField(
                  controller: trackingController,
                  decoration: const InputDecoration(
                    labelText: 'Tracking Number',
                    hintText: 'e.g., TRK123456789',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Update order with tracking number if provided
                  _updateOrderStatus(context, OrderStatus.shipped, viewModel);
                },
                child: const Text('Ship Order'),
              ),
            ],
          ),
    );
  }

  void _copyTrackingNumber(BuildContext context) {
    // TODO: Implement copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tracking number copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _contactCustomer(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customer contact feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _printOrderDetails(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fiction':
        return Colors.purple.shade600;
      case 'non-fiction':
        return Colors.blue.shade600;
      case 'academic':
        return Colors.green.shade600;
      case 'textbook':
        return Colors.orange.shade600;
      case 'children':
        return Colors.pink.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule_outlined;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.shipped:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
      case OrderStatus.rejected:
        return Icons.close_rounded;
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange.shade600;
      case OrderStatus.confirmed:
        return Colors.blue.shade600;
      case OrderStatus.shipped:
        return Colors.indigo.shade600;
      case OrderStatus.delivered:
        return Colors.green.shade600;
      case OrderStatus.cancelled:
        return Colors.red.shade600;
      case OrderStatus.rejected:
        return Colors.red.shade700;
    }
  }
}
