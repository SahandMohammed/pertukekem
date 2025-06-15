import 'package:flutter/material.dart';
import '../../../library/model/library_model.dart';
import '../../../library/service/saved_books_service.dart';
import '../../../listings/view/listing_details_screen.dart';
import '../../../listings/model/listing_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavedBooksScreen extends StatefulWidget {
  const SavedBooksScreen({super.key});

  @override
  State<SavedBooksScreen> createState() => _SavedBooksScreenState();
}

class _SavedBooksScreenState extends State<SavedBooksScreen> {
  final SavedBooksService _savedBooksService = SavedBooksService();
  List<LibraryBook> _savedBooks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedBooks();
  }

  Future<void> _loadSavedBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final savedBooks = await _savedBooksService.getSavedBooks();
      setState(() {
        _savedBooks = savedBooks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeSavedBook(LibraryBook book) async {
    try {
      await _savedBooksService.unsaveBook(book.bookId);
      setState(() {
        _savedBooks.removeWhere((b) => b.bookId == book.bookId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book removed from saved books'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing book: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRemoveConfirmation(LibraryBook book) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Book'),
            content: Text('Remove "${book.title}" from your saved books?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _removeSavedBook(book);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  Future<void> _navigateToBookDetails(LibraryBook book) async {
    try {
      // Try to fetch the original listing
      final listingDoc =
          await FirebaseFirestore.instance
              .collection('listings')
              .doc(book.bookId)
              .get();

      if (listingDoc.exists && mounted) {
        final listing = Listing.fromFirestore(listingDoc, null);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ListingDetailsScreen(listing: listing),
          ),
        );
      } else {
        // Listing not found, show message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This book listing is no longer available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening book details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Books'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSavedBooks,
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
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
                      'Error loading saved books',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSavedBooks,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _savedBooks.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 64,
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No saved books yet',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Books you save will appear here',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigate back to the main dashboard to browse books
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.explore),
                      label: const Text('Browse Books'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadSavedBooks,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _savedBooks.length,
                  itemBuilder: (context, index) {
                    final book = _savedBooks[index];
                    return _buildBookCard(book);
                  },
                ),
              ),
    );
  }

  Widget _buildBookCard(LibraryBook book) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToBookDetails(book),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      book.coverUrl != null && book.coverUrl!.isNotEmpty
                          ? Image.network(
                            book.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: colorScheme.surfaceVariant,
                                child: Icon(
                                  Icons.book,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                              );
                            },
                          )
                          : Container(
                            color: colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.book,
                              color: colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 16),

              // Book details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${book.author}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    if (book.sellerName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.store_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            book.sellerName,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          book.bookType == 'ebook'
                              ? Icons.download_outlined
                              : Icons.local_shipping_outlined,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          book.bookType == 'ebook' ? 'Digital' : 'Physical',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                onSelected: (action) {
                  switch (action) {
                    case 'remove':
                      _showRemoveConfirmation(book);
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Remove', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                child: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
