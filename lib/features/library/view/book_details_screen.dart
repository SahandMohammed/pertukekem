import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/library_model.dart';
import '../viewmodel/library_viewmodel.dart';
import '../service/download_service.dart';
import '../service/saved_books_service.dart';
import 'ebook_reader_screen.dart';
import '../../listings/model/listing_model.dart';
import '../../listings/view/add_edit_listing_screen.dart';
import '../../listings/viewmodel/manage_listings_viewmodel.dart';

class BookDetailsScreen extends StatefulWidget {
  final LibraryBook book;

  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final DownloadService _downloadService = DownloadService();
  final SavedBooksService _savedBooksService = SavedBooksService();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isFileAvailable = false;
  bool _isStoreAccount = false;
  bool _isBookSaved = false;
  bool _isLoadingSavedState = true;
  @override
  void initState() {
    super.initState();
    _checkFileAvailability();
    _checkUserType();
    _checkSavedState();
  }

  Future<void> _checkUserType() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        // Check if the user has a store document
        final storeDoc =
            await FirebaseFirestore.instance
                .collection('stores')
                .doc(currentUser.uid)
                .get();

        setState(() {
          _isStoreAccount = storeDoc.exists;
        });
      } catch (e) {
        print('Error checking user type: $e');
        setState(() {
          _isStoreAccount = false;
        });
      }
    }
  }

  Future<void> _checkFileAvailability() async {
    if (widget.book.isEbook && widget.book.localFilePath != null) {
      final available = await _downloadService.isFileDownloaded(
        widget.book.localFilePath,
      );
      setState(() {
        _isFileAvailable = available;
      });
    }
  }

  Future<void> _downloadBook() async {
    if (widget.book.downloadUrl == null || widget.book.downloadUrl!.isEmpty) {
      _showErrorSnackBar('Download URL not available');
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final fileName = '${widget.book.title}.pdf'; // Default to PDF
      final localPath = await _downloadService.downloadEbook(
        downloadUrl: widget.book.downloadUrl!,
        bookId: widget.book.bookId,
        fileName: fileName,
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
      );

      // Update library service to mark as downloaded
      final viewModel = context.read<LibraryViewModel>();
      await viewModel.markBookAsDownloaded(
        libraryBookId: widget.book.id,
        localFilePath: localPath,
      );

      setState(() {
        _isFileAvailable = true;
        _isDownloading = false;
      });

      _showSuccessSnackBar('Book downloaded successfully!');
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      _showErrorSnackBar('Failed to download book: $e');
    }
  }

  Future<void> _deleteDownload() async {
    if (widget.book.localFilePath == null) return;

    try {
      await _downloadService.deleteFile(widget.book.localFilePath!);

      // Update library service
      final viewModel = context.read<LibraryViewModel>();
      await viewModel.removeDownload(widget.book.id);

      setState(() {
        _isFileAvailable = false;
      });

      _showSuccessSnackBar('Download removed successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to remove download: $e');
    }
  }

  void _openReader() {
    if (!_isFileAvailable) {
      _showErrorSnackBar('Book needs to be downloaded first');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EbookReaderScreen(book: widget.book),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _checkSavedState() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLoadingSavedState = false);
      return;
    }

    setState(() => _isLoadingSavedState = true);
    try {
      final isSaved = await _savedBooksService.isBookSaved(widget.book.bookId);
      setState(() {
        _isBookSaved = isSaved;
      });
    } catch (e) {
      print('Error checking saved state: $e');
    } finally {
      setState(() => _isLoadingSavedState = false);
    }
  }

  Future<void> _toggleSavedState() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('Please sign in to save books');
      return;
    }

    try {
      if (_isBookSaved) {
        await _savedBooksService.unsaveBook(widget.book.bookId);
        setState(() => _isBookSaved = false);
        _showSuccessSnackBar('Book removed from saved');
      } else {
        await _savedBooksService.saveBook(widget.book);
        setState(() => _isBookSaved = true);
        _showSuccessSnackBar('Book saved to your collection');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.book.userId)
              .collection('library')
              .doc(widget.book.id)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.book.title)),
            body: const Center(child: Text('Book not found.')),
          );
        }

        final bookData = snapshot.data!.data() as Map<String, dynamic>;
        final updatedBook = widget.book.copyWith(
          currentPage: bookData['currentPage'],
          totalPages: bookData['totalPages'],
          isCompleted: bookData['isCompleted'],
        );

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: colorScheme.primary,
                actions: [
                  IconButton(
                    onPressed: _toggleSavedState,
                    icon:
                        _isLoadingSavedState
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Icon(
                              _isBookSaved
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isBookSaved ? Colors.red : Colors.white,
                            ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(updatedBook.title),
                  background:
                      updatedBook.coverUrl != null
                          ? Image.network(
                            updatedBook.coverUrl!,
                            fit: BoxFit.cover,
                          )
                          : _buildCoverPlaceholder(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReadingProgress(updatedBook),
                      const SizedBox(height: 16),
                      _buildBookInformation(updatedBook),
                      const SizedBox(height: 16),
                      _buildPurchaseInformation(updatedBook),
                      const SizedBox(height: 16),
                      // Show different actions based on user type
                      if (_isStoreAccount)
                        _buildStoreActions(updatedBook)
                      else if (updatedBook.isEbook)
                        _buildEbookActions(updatedBook),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(Icons.book, size: 60, color: Colors.grey.shade500),
    );
  }

  Widget _buildEbookActions(LibraryBook book) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'E-Book Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isDownloading)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Downloading... ${(_downloadProgress * 100).toInt()}%',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              )
            else if (_isFileAvailable)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openReader,
                      icon: const Icon(Icons.auto_stories),
                      label: const Text('Read Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _deleteDownload,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove Download'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _downloadBook,
                  icon: const Icon(Icons.download),
                  label: const Text('Download for Offline Reading'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreActions(LibraryBook book) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Store Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _editListing(book),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Listing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _deleteListing(book),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Listing'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editListing(LibraryBook book) async {
    try {
      // First, get the listing ID from the book
      // You'll need to query the listings collection to find the listing by book details
      final listingsQuery =
          await FirebaseFirestore.instance
              .collection('listings')
              .where('title', isEqualTo: book.title)
              .where('author', isEqualTo: book.author)
              .get();

      if (listingsQuery.docs.isNotEmpty) {
        final listingDoc = listingsQuery.docs.first;

        // Create a Listing object from the found data
        final listing = Listing.fromFirestore(listingDoc, null);

        // Navigate to AddEditListingScreen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditListingScreen(listing: listing),
          ),
        );

        if (result == 'updated' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find the listing to edit'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading listing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteListing(LibraryBook book) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete Listing'),
            content: Text('Are you sure you want to delete "${book.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      try {
        // Query the listings collection to find the corresponding listing
        final listingsQuery =
            await FirebaseFirestore.instance
                .collection('listings')
                .where('title', isEqualTo: book.title)
                .where('author', isEqualTo: book.author)
                .get();

        if (listingsQuery.docs.isNotEmpty) {
          final listingDoc = listingsQuery.docs.first;
          final listingData = listingDoc.data();

          // Verify this listing belongs to the current user
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            final sellerRef = listingData['sellerRef'] as DocumentReference;
            final isOwner =
                sellerRef.path == 'users/${currentUser.uid}' ||
                sellerRef.path == 'stores/${currentUser.uid}';

            if (isOwner) {
              // Use ManageListingsViewModel to delete the listing
              final viewModel = Provider.of<ManageListingsViewModel>(
                context,
                listen: false,
              );

              await viewModel.deleteListing(listingDoc.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Listing deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Navigate back to previous screen
                Navigator.pop(context);
              }
            } else {
              throw Exception('You are not authorized to delete this listing');
            }
          } else {
            throw Exception('User not authenticated');
          }
        } else {
          throw Exception('Listing not found');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting listing: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildReadingProgress(LibraryBook book) {
    final progress = book.readingProgress;
    final currentPage = book.currentPage ?? 0;
    final totalPages = book.totalPages ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Progress',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page $currentPage of $totalPages',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  '${(progress * 100).toInt()}% Complete',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (book.lastReadDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last read: ${DateFormat('MMM dd, yyyy').format(book.lastReadDate!)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookInformation(LibraryBook book) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book Information',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Title', book.title),
            _buildInfoRow('Author', book.author),
            if (book.isbn != null && book.isbn!.isNotEmpty)
              _buildInfoRow('ISBN', book.isbn!),
            _buildInfoRow('Type', book.isEbook ? 'E-Book' : 'Physical Book'),
            if (book.totalPages != null)
              _buildInfoRow('Pages', book.totalPages.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseInformation(LibraryBook book) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Purchase Information',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Purchase Date',
              DateFormat('MMM dd, yyyy').format(book.purchaseDate),
            ),
            _buildInfoRow(
              'Price Paid',
              NumberFormat.currency(symbol: '\$').format(book.purchasePrice),
            ),
            if (book.transactionId.isNotEmpty)
              _buildInfoRow('Transaction ID', book.transactionId),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
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
}
