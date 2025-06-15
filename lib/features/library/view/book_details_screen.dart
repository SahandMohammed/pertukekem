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
  bool _isInitializing = true;

  // Store the updated book information after download
  LibraryBook? _updatedBook;

  // Get the current book (updated if available, otherwise original)
  LibraryBook get currentBook => _updatedBook ?? widget.book;

  @override
  void initState() {
    super.initState();
    _initializeScreenData();
  }

  Future<void> _initializeScreenData() async {
    // Initialize all data in parallel to reduce loading time and state changes
    await Future.wait([
      _checkFileAvailability(),
      _checkUserType(),
      _checkSavedState(),
    ]);

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
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

        if (mounted) {
          setState(() {
            _isStoreAccount = storeDoc.exists;
          });
        }
      } catch (e) {
        print('Error checking user type: $e');
        if (mounted) {
          setState(() {
            _isStoreAccount = false;
          });
        }
      }
    }
  }

  Future<void> _checkFileAvailability() async {
    if (currentBook.isEbook && currentBook.localFilePath != null) {
      final available = await _downloadService.isFileDownloaded(
        currentBook.localFilePath,
      );
      if (mounted) {
        setState(() {
          _isFileAvailable = available;
        });
      }
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
      ); // Update library service to mark as downloaded
      final viewModel = context.read<LibraryViewModel>();
      await viewModel.markBookAsDownloaded(
        libraryBookId: widget.book.id,
        localFilePath: localPath,
      );

      // Update the local book object with the new file path
      setState(() {
        _updatedBook = widget.book.copyWith(
          localFilePath: localPath,
          isDownloaded: true,
        );
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
    if (currentBook.localFilePath == null) return;

    try {
      await _downloadService.deleteFile(currentBook.localFilePath!);

      // Update library service
      final viewModel = context.read<LibraryViewModel>();
      await viewModel.removeDownload(widget.book.id);
      setState(() {
        _updatedBook = widget.book.copyWith(
          localFilePath: null,
          isDownloaded: false,
        );
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
        builder: (context) => EbookReaderScreen(book: currentBook),
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
      if (mounted) {
        setState(() => _isLoadingSavedState = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoadingSavedState = true);
    }

    try {
      final isSaved = await _savedBooksService.isBookSaved(widget.book.bookId);
      if (mounted) {
        setState(() {
          _isBookSaved = isSaved;
          _isLoadingSavedState = false;
        });
      }
    } catch (e) {
      print('Error checking saved state: $e');
      if (mounted) {
        setState(() => _isLoadingSavedState = false);
      }
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show loading indicator during initialization
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(widget.book.title),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildModernAppBar(theme),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Action Buttons Section - Moved to top
                _buildActionButtonsSection(theme),
                const SizedBox(height: 24),

                // Book Content Sections
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildReadingProgressCard(theme),
                      const SizedBox(height: 16),
                      _buildBookInformationCard(theme),
                      const SizedBox(height: 16),
                      _buildPurchaseInformationCard(theme),
                      const SizedBox(height: 24),
                      if (_isStoreAccount) _buildStoreActionsCard(theme),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _toggleSavedState,
            icon:
                _isLoadingSavedState
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                    : Icon(
                      _isBookSaved ? Icons.favorite : Icons.favorite_border,
                      color:
                          _isBookSaved
                              ? colorScheme.error
                              : colorScheme.onSurface,
                    ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        centerTitle: true,
        titlePadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            currentBook.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colorScheme.surfaceContainer, colorScheme.surface],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (currentBook.coverUrl != null &&
                  currentBook.coverUrl!.isNotEmpty)
                Positioned.fill(
                  child: ClipRRect(
                    child: Image.network(
                      currentBook.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              _buildModernCoverPlaceholder(theme),
                    ),
                  ),
                )
              else
                _buildModernCoverPlaceholder(theme),

              // Gradient overlay for better text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        colorScheme.surface.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernCoverPlaceholder(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 80,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'E-Book',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsSection(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    if (!currentBook.isEbook && !_isStoreAccount) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (_isDownloading)
            _buildDownloadProgressSection(theme)
          else if (currentBook.isEbook)
            _buildEbookActionButtons(theme)
          else if (_isStoreAccount)
            _buildStoreActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildDownloadProgressSection(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.download_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'Downloading...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${(_downloadProgress * 100).toInt()}%',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _downloadProgress,
          backgroundColor: colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          borderRadius: BorderRadius.circular(8),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          'Please wait while your book is being downloaded...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEbookActionButtons(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    if (_isFileAvailable) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openReader,
              icon: const Icon(Icons.chrome_reader_mode_rounded),
              label: const Text('Start Reading'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deleteDownload,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Remove Download'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(color: colorScheme.outline),
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _downloadBook,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Download Book'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildStoreActionButtons(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _editListing(currentBook),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit Listing'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _deleteListing(currentBook),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete Listing'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: colorScheme.error),
              foregroundColor: colorScheme.error,
            ),
          ),
        ),
      ],
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
              // Delete the listing directly
              await FirebaseFirestore.instance
                  .collection('listings')
                  .doc(listingDoc.id)
                  .delete();

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

  Widget _buildReadingProgressCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final progress = currentBook.readingProgress;
    final currentPage = currentBook.currentPage ?? 0;
    final totalPages = currentBook.totalPages ?? 0;

    if (!currentBook.isEbook || totalPages == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Reading Progress',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Page $currentPage of $totalPages',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  minHeight: 8,
                ),
              ],
            ),

            if (currentBook.isCompleted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Completed',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookInformationCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Book Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(theme, 'Title', currentBook.title),
            _buildInfoRow(theme, 'Author', currentBook.author),
            if (currentBook.isbn != null && currentBook.isbn!.isNotEmpty)
              _buildInfoRow(theme, 'ISBN', currentBook.isbn!),
            _buildInfoRow(
              theme,
              'Type',
              currentBook.isEbook ? 'E-Book' : 'Physical Book',
            ),
            if (currentBook.totalPages != null)
              _buildInfoRow(theme, 'Pages', '${currentBook.totalPages}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseInformationCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: colorScheme.onTertiaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Purchase Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              theme,
              'Price',
              'RM ${currentBook.purchasePrice.toStringAsFixed(2)}',
            ),
            _buildInfoRow(
              theme,
              'Purchase Date',
              DateFormat('MMM dd, yyyy').format(currentBook.purchaseDate),
            ),
            if (currentBook.transactionId.isNotEmpty)
              _buildInfoRow(theme, 'Transaction ID', currentBook.transactionId),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreActionsCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.errorContainer.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.error.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.store_rounded,
                    color: colorScheme.onErrorContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Store Management',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'As a store owner, you can manage this listing.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
