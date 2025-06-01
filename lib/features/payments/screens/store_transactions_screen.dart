import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../authentication/viewmodels/auth_viewmodel.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class StoreTransactionsScreen extends StatefulWidget {
  const StoreTransactionsScreen({super.key});

  @override
  State<StoreTransactionsScreen> createState() =>
      _StoreTransactionsScreenState();
}

class _StoreTransactionsScreenState extends State<StoreTransactionsScreen> {
  final TransactionService _transactionService = TransactionService();
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.user?.storeId != null) {
        if (_selectedFilter == 'all') {
          _transactions = await _transactionService.getTransactionsBySellerId(
            authViewModel.user!.storeId!,
          );
        } else {
          _transactions = await _transactionService.getTransactionsByStatus(
            _selectedFilter,
          );
          // Filter by store seller ID
          _transactions =
              _transactions
                  .where((t) => t.sellerId == authViewModel.user!.storeId)
                  .toList();
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchTransactions() async {
    if (_searchController.text.isEmpty) {
      await _loadTransactions();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final transactions = await _transactionService.searchTransactions(
        transactionId: _searchController.text,
      );

      // Filter by store seller ID
      setState(() {
        _transactions =
            transactions
                .where((t) => t.sellerId == authViewModel.user?.storeId)
                .toList();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.user;

    // Check if user has a store
    if (user?.storeId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Store Transactions')),
        body: const Center(
          child: Text('You need to set up a store to view transactions.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Sales'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Transaction ID',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadTransactions();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _searchTransactions(),
                ),
                const SizedBox(height: 16),

                // Status filter
                Row(
                  children: [
                    const Text('Filter: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedFilter = value;
                            });
                            _loadTransactions();
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Sales'),
                          ),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Completed'),
                          ),
                          DropdownMenuItem(
                            value: 'failed',
                            child: Text('Failed'),
                          ),
                          DropdownMenuItem(
                            value: 'refunded',
                            child: Text('Refunded'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _searchTransactions,
                      child: const Text('Search'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Transactions list
          Expanded(child: _buildTransactionsList()),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTransactions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No sales found'),
            SizedBox(height: 8),
            Text(
              'Sales transactions will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return _buildTransactionCard(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final textTheme = Theme.of(context).textTheme;

    Color statusColor;
    IconData statusIcon;

    switch (transaction.status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'refunded':
        statusColor = Colors.blue;
        statusIcon = Icons.undo;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with transaction ID and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transaction.id,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(transaction.status).toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Transaction details
            _buildDetailRow('Item', transaction.listingTitle),
            _buildDetailRow(
              'Amount',
              '\$${transaction.amount.toStringAsFixed(2)}',
            ),
            _buildDetailRow(
              'Payment Method',
              _formatPaymentMethod(transaction.paymentMethod),
            ),
            _buildDetailRow('Date', _formatDate(transaction.createdAt)),
            if (transaction.completedAt != null)
              _buildDetailRow(
                'Completed',
                _formatDate(transaction.completedAt!),
              ),

            const SizedBox(height: 12),

            // Customer info (if available)
            if (transaction.paymentDetails != null &&
                transaction.paymentDetails!.containsKey('email'))
              _buildDetailRow(
                'Customer Email',
                transaction.paymentDetails!['email'],
              ),

            const SizedBox(height: 8),

            // Earnings highlight for completed transactions
            if (transaction.status == 'completed')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Sale completed - \$${transaction.amount.toStringAsFixed(2)} earned',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      default:
        return status.toUpperCase();
    }
  }

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'credit_card':
        return 'Credit Card';
      case 'paypal':
        return 'PayPal';
      case 'apple_pay':
        return 'Apple Pay';
      default:
        return method;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }
}
