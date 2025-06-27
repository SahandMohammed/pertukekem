import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/book_request_viewmodel.dart';
import '../../../dashboards/model/store_model.dart';
import 'store_selection_screen.dart';

class RequestBookScreen extends StatefulWidget {
  final StoreModel? preSelectedStore;

  const RequestBookScreen({
    super.key,
    this.preSelectedStore,
  });

  @override
  State<RequestBookScreen> createState() => _RequestBookScreenState();
}

class _RequestBookScreenState extends State<RequestBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookTitleController = TextEditingController();
  final _noteController = TextEditingController();

  StoreModel? _selectedStore;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStore = widget.preSelectedStore;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookRequestViewModel>().loadAvailableStores();
    });
  }

  @override
  void dispose() {
    _bookTitleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request a Book'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.book_outlined,
                              color: colorScheme.onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Request a Book',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Can\'t find the book you\'re looking for? Request it from your favorite store!',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Store Selection
              Text(
                'Select Store',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Consumer<BookRequestViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading && viewModel.availableStores.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  if (viewModel.availableStores.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.store_outlined,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No stores available',
                              style: textTheme.titleMedium,
                            ),
                            Text(
                              'No verified stores found for book requests',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedStore != null
                            ? colorScheme.primary.withOpacity(0.3)
                            : colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final selectedStore = await Navigator.of(context).push<StoreModel>(
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider.value(
                              value: context.read<BookRequestViewModel>(),
                              child: StoreSelectionScreen(
                                initialSelection: _selectedStore,
                              ),
                            ),
                          ),
                        );

                        if (selectedStore != null) {
                          setState(() {
                            _selectedStore = selectedStore;
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.store_outlined,
                              color: _selectedStore != null
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedStore != null ? 'Store Selected' : 'Choose a store',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: _selectedStore != null
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_selectedStore != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedStore!.storeName,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_selectedStore!.description != null &&
                                        _selectedStore!.description!.isNotEmpty)
                                      Text(
                                        _selectedStore!.description!,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ] else
                                    Text(
                                      'Tap to select a store to request a book from',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Book Title Input
              Text(
                'Book Information',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: TextFormField(
                  controller: _bookTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Book Title',
                    hintText: 'Enter the title of the book you\'re looking for',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a book title';
                    }
                    if (value.trim().length < 2) {
                      return 'Book title must be at least 2 characters';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Note Input
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    hintText:
                        'Author, edition, specific requirements, etc...',
                    prefixIcon: Icon(Icons.note_outlined),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: Consumer<BookRequestViewModel>(
                  builder: (context, viewModel, child) {
                    return FilledButton(
                      onPressed: (viewModel.isSubmitting || _isLoading)
                          ? null
                          : _submitRequest,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: viewModel.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Submit Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Info Card
              Card(
                elevation: 0,
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your request will be sent to the store owner. They will review it and respond with availability and pricing information.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a store'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final viewModel = context.read<BookRequestViewModel>();
    final success = await viewModel.submitBookRequest(
      storeId: _selectedStore!.storeId,
      storeName: _selectedStore!.storeName,
      bookTitle: _bookTitleController.text.trim(),
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Book request submitted successfully!'),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else if (mounted && viewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
