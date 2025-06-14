import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../model/order_model.dart' as order_model;
import '../../viewmodel/store_order_viewmodel.dart';
import 'store_order_details_screen.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  String selectedFilter = 'all';

  final Map<String, Map<String, dynamic>> filterConfigs = {
    'all': {'label': 'All Orders', 'icon': Icons.list},
    'pending': {'label': 'Pending', 'icon': Icons.pending},
    'confirmed': {'label': 'Confirmed', 'icon': Icons.check_circle_outline},
    'shipped': {'label': 'Shipped', 'icon': Icons.local_shipping},
    'delivered': {'label': 'Delivered', 'icon': Icons.check_circle},
    'cancelled': {'label': 'Cancelled', 'icon': Icons.cancel},
    'rejected': {'label': 'Rejected', 'icon': Icons.block},
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreOrderViewModel>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Manage Orders',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.filter_list,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: _buildFilterChips(),
          ),
          Expanded(child: _buildOrdersList(context)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filterConfigs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filterKey = filterConfigs.keys.toList()[index];
          final filterConfig = filterConfigs[filterKey]!;
          final isSelected = selectedFilter == filterKey;
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filterConfig['icon'] as IconData,
                  size: 16,
                  color:
                      isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  filterConfig['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color:
                        isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                selectedFilter = filterKey;
              });

              // Update the viewmodel filter
              final viewModel = context.read<StoreOrderViewModel>();
              if (filterKey == 'all') {
                viewModel.loadOrders();
              } else {
                final status = order_model.OrderStatus.values.firstWhere(
                  (s) => s.name == filterKey,
                );
                viewModel.loadOrdersWithFilter(status);
              }
            },
            backgroundColor: colorScheme.surface,
            selectedColor: colorScheme.primary,
            side: BorderSide(
              color:
                  isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withOpacity(0.5),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context) {
    return Consumer<StoreOrderViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.error != null) {
          return _buildErrorState(context, viewModel.error!);
        }

        final filteredOrders = _filterOrders(viewModel.orders);

        if (filteredOrders.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () => viewModel.refreshOrders(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: filteredOrders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildOrderCard(context, filteredOrders[index]);
            },
          ),
        );
      },
    );
  }

  List<order_model.Order> _filterOrders(List<order_model.Order> orders) {
    if (selectedFilter == 'all') {
      return orders;
    }
    return orders
        .where((order) => order.status.name == selectedFilter)
        .toList();
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Error Loading Orders',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  context.read<StoreOrderViewModel>().clearError();
                  context.read<StoreOrderViewModel>().loadOrders();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Orders Found',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No orders match the selected filter',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pull down to refresh',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Orders',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Advanced filtering options coming soon!'),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildOrderCard(BuildContext context, order_model.Order order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final statusColor = _getStatusColor(order.status.name);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToOrderDetails(context, order),
          borderRadius: BorderRadius.circular(16),
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
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getStatusIcon(order.status.name),
                        color: statusColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.id.substring(0, 8).toUpperCase()}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy • hh:mm a',
                            ).format(order.createdAt.toDate()),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(order.status.name),
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantity',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.quantity} item${order.quantity > 1 ? 's' : ''}',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Amount',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${NumberFormat('#,##0.00').format(order.totalAmount)}',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (order.shippingAddress != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.shippingAddress!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            () => _navigateToOrderDetails(context, order),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(
                            color: colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: PopupMenuButton<order_model.OrderStatus>(
                        icon: Icon(
                          Icons.more_horiz,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        onSelected: (newStatus) {
                          _updateOrderStatus(context, order, newStatus);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) {
                          final availableStatuses =
                              order_model.OrderStatus.values
                                  .where((status) => status != order.status)
                                  .toList();

                          return availableStatuses
                              .map(
                                (status) => PopupMenuItem(
                                  value: status,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status.name),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Mark as ${_getStatusText(status.name)}',
                                        style: textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'rejected':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  void _navigateToOrderDetails(BuildContext context, order_model.Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: order)),
    );
  }

  void _updateOrderStatus(
    BuildContext context,
    order_model.Order order,
    order_model.OrderStatus newStatus,
  ) async {
    if (!mounted) return;

    final viewModel = context.read<StoreOrderViewModel>();
    final success = await viewModel.updateOrderStatus(order.id, newStatus);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order status updated to ${_getStatusText(newStatus.name)}',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update order status'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
