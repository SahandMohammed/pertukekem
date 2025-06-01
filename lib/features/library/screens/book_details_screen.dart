import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/library_model.dart';
import '../viewmodels/library_viewmodel.dart';
import '../services/download_service.dart';
import 'ebook_reader_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  final LibraryBook book;

  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final DownloadService _downloadService = DownloadService();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isFileAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkFileAvailability();
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book Cover
                        Container(
                          width: 120,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                widget.book.coverUrl != null &&
                                        widget.book.coverUrl!.isNotEmpty
                                    ? Image.network(
                                      widget.book.coverUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return _buildCoverPlaceholder();
                                      },
                                    )
                                    : _buildCoverPlaceholder(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Book Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                widget.book.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.book.author,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      widget.book.isEbook
                                          ? Colors.blue
                                          : Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.book.isEbook
                                          ? Icons.tablet_mac
                                          : Icons.menu_book,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.book.isEbook
                                          ? 'E-Book'
                                          : 'Physical Book',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Buttons
                  if (widget.book.isEbook) ...[
                    _buildEbookActions(),
                    const SizedBox(height: 24),
                  ],

                  // Reading Progress (for ebooks)
                  if (widget.book.isEbook &&
                      widget.book.totalPages != null) ...[
                    _buildReadingProgress(),
                    const SizedBox(height: 24),
                  ],

                  // Book Information
                  _buildBookInformation(),
                  const SizedBox(height: 24),

                  // Purchase Information
                  _buildPurchaseInformation(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(Icons.book, size: 60, color: Colors.grey.shade500),
    );
  }

  Widget _buildEbookActions() {
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

  Widget _buildReadingProgress() {
    final progress = widget.book.readingProgress;
    final currentPage = widget.book.currentPage ?? 0;
    final totalPages = widget.book.totalPages ?? 0;

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
            if (widget.book.lastReadDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last read: ${DateFormat('MMM dd, yyyy').format(widget.book.lastReadDate!)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookInformation() {
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
            _buildInfoRow('Title', widget.book.title),
            _buildInfoRow('Author', widget.book.author),
            if (widget.book.isbn != null && widget.book.isbn!.isNotEmpty)
              _buildInfoRow('ISBN', widget.book.isbn!),
            _buildInfoRow(
              'Type',
              widget.book.isEbook ? 'E-Book' : 'Physical Book',
            ),
            if (widget.book.totalPages != null)
              _buildInfoRow('Pages', widget.book.totalPages.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseInformation() {
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
              DateFormat('MMM dd, yyyy').format(widget.book.purchaseDate),
            ),
            _buildInfoRow(
              'Price Paid',
              NumberFormat.currency(
                symbol: '\$',
              ).format(widget.book.purchasePrice),
            ),
            if (widget.book.transactionId.isNotEmpty)
              _buildInfoRow('Transaction ID', widget.book.transactionId),
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
