import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/library_model.dart';
import '../viewmodel/library_viewmodel.dart';
import '../viewmodel/book_details_viewmodel.dart';
import 'ebook_reader_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  final LibraryBook book;

  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _downloadController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _downloadAnimation;

  BookDetailsViewModel? _bookDetailsViewModel;
  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _downloadController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _downloadAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _downloadController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize BookDetailsViewModel if not already done
    if (_bookDetailsViewModel == null) {
      final libraryViewModel = context.read<LibraryViewModel>();
      _bookDetailsViewModel = BookDetailsViewModel(
        libraryViewModel,
        widget.book,
      );

      // Listen to ViewModel state changes
      _bookDetailsViewModel!.addListener(_onViewModelChanged);
    }
  }

  void _onViewModelChanged() {
    if (!mounted) return;

    final viewModel = _bookDetailsViewModel!;

    // Handle download animation
    if (viewModel.isDownloading) {
      _downloadController.forward();
    } else {
      _downloadController.reset();
    }

    // Handle messages
    if (viewModel.errorMessage != null) {
      _showErrorSnackBar(viewModel.errorMessage!);
      viewModel.clearMessages();
    }

    if (viewModel.successMessage != null) {
      _showSuccessSnackBar(viewModel.successMessage!);
      viewModel.clearMessages();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _downloadController.dispose();
    _bookDetailsViewModel?.removeListener(_onViewModelChanged);
    _bookDetailsViewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Consumer<LibraryViewModel>(
      builder: (context, libraryViewModel, child) {
        if (_bookDetailsViewModel == null) return const SizedBox.shrink();

        return ChangeNotifierProvider<BookDetailsViewModel>.value(
          value: _bookDetailsViewModel!,
          child: Consumer<BookDetailsViewModel>(
            builder:
                (context, bookDetailsViewModel, child) => Scaffold(
                  backgroundColor: colorScheme.surface,
                  body: CustomScrollView(
                    slivers: [
                      _buildAppBar(context, colorScheme),
                      SliverToBoxAdapter(
                        child: AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder:
                              (context, child) => Opacity(
                                opacity: _fadeAnimation.value,
                                child: Transform.translate(
                                  offset: Offset(0, _slideAnimation.value),
                                  child: Column(
                                    children: [
                                      _buildBookHero(context, size),
                                      _buildBookInfo(context, theme),
                                      _buildActionButtons(
                                        context,
                                        bookDetailsViewModel,
                                        theme,
                                      ),
                                      _buildReadingProgress(context, theme),
                                      _buildBookDescription(context, theme),
                                      _buildBookMetadata(context, theme),
                                      const SizedBox(height: 32),
                                    ],
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _shareBook,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.share_outlined,
              size: 20,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Book Details',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildBookHero(BuildContext context, Size size) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Hero(
          tag: 'book_cover_${widget.book.id}',
          child: Container(
            width: size.width * 0.5,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child:
                  widget.book.coverUrl != null &&
                          widget.book.coverUrl!.isNotEmpty
                      ? Image.network(
                        widget.book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildBookPlaceholder();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                color: colorScheme.primary,
                              ),
                            ),
                          );
                        },
                      )
                      : _buildBookPlaceholder(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookPlaceholder() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(
          Icons.book_outlined,
          size: 64,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildBookInfo(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Text(
            widget.book.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'by ${widget.book.author}',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(
                icon: Icons.book_outlined,
                label: widget.book.bookType.toUpperCase(),
                color: colorScheme.primaryContainer,
                textColor: colorScheme.onPrimaryContainer,
              ),
              if (widget.book.isbn != null) ...[
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.qr_code,
                  label: 'ISBN',
                  color: colorScheme.secondaryContainer,
                  textColor: colorScheme.onSecondaryContainer,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    BookDetailsViewModel viewModel,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final book = viewModel.currentBook ?? widget.book;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Primary Action Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child:
                book.isDownloaded
                    ? FilledButton.icon(
                      onPressed: () => _openBook(context),
                      icon: const Icon(Icons.auto_stories, size: 24),
                      label: Text(
                        'Read Book',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    )
                    : viewModel.isDownloading
                    ? _buildDownloadProgressButton(colorScheme, viewModel)
                    : FilledButton.icon(
                      onPressed: () => viewModel.downloadBook(),
                      icon: const Icon(Icons.download, size: 24),
                      label: Text(
                        'Download Book',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
          ),
          const SizedBox(height: 12),
          // Secondary Actions
          Row(
            children: [
              if (book.isDownloaded)
                SizedBox(
                  width: 56,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _showRemoveDownloadDialog(viewModel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.delete_outline, size: 20),
                  ),
                ),
              if (book.isDownloaded) const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    fixedSize: const Size.fromHeight(48),
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _shareBook,
                  icon: const Icon(Icons.share_outlined, size: 20),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgressButton(
    ColorScheme colorScheme,
    BookDetailsViewModel viewModel,
  ) {
    return AnimatedBuilder(
      animation: _downloadAnimation,
      builder:
          (context, child) => Container(
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Progress Background
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                // Progress Fill
                FractionallySizedBox(
                  widthFactor: viewModel.downloadProgress,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // Content
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          value: viewModel.downloadProgress,
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Downloading... ${(viewModel.downloadProgress * 100).toInt()}%',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
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

  Widget _buildReadingProgress(BuildContext context, ThemeData theme) {
    return Consumer<BookDetailsViewModel>(
      builder: (context, viewModel, child) {
        final progressData = viewModel.getReadingProgressData();

        if (!progressData['hasProgress']) {
          return const SizedBox.shrink();
        }

        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;
        final progress = progressData['progress'] as double;
        final currentPage = progressData['currentPage'] as int;
        final totalPages = progressData['totalPages'] as int;
        final isCompleted = progressData['isCompleted'] as bool;
        final lastReadDate = progressData['lastReadDate'] as DateTime?;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reading Progress',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isCompleted
                              ? colorScheme.primaryContainer
                              : colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isCompleted
                          ? 'Completed'
                          : '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color:
                            isCompleted
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? colorScheme.primary : colorScheme.secondary,
                ),
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page $currentPage of $totalPages',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (lastReadDate != null)
                    Text(
                      'Last read: ${_formatDate(lastReadDate)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookDescription(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Consumer<BookDetailsViewModel>(
      builder: (context, viewModel, child) {
        // Mock description - in real app, this would come from the book data
        final description =
            'Immerse yourself in this captivating literary work that takes readers on an extraordinary journey through compelling narratives and rich character development. This book offers profound insights and entertainment that will keep you engaged from the first page to the last.';

        return Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedCrossFade(
                firstChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description.length > 150
                          ? '${description.substring(0, 150)}...'
                          : description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    if (description.length > 150)
                      TextButton(
                        onPressed: viewModel.toggleDescription,
                        child: Text('Read more'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    TextButton(
                      onPressed: viewModel.toggleDescription,
                      child: Text('Show less'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                crossFadeState:
                    viewModel.showFullDescription
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookMetadata(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book Information',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildMetadataRow(
            'Purchase Date',
            _formatDate(widget.book.purchaseDate),
            Icons.calendar_today_outlined,
            theme,
          ),
          _buildMetadataRow(
            'Price Paid',
            'RM ${widget.book.purchasePrice.toStringAsFixed(2)}',
            Icons.payments_outlined,
            theme,
          ),
          if (widget.book.isbn != null)
            _buildMetadataRow(
              'ISBN',
              widget.book.isbn!,
              Icons.qr_code_outlined,
              theme,
            ),
          _buildMetadataRow(
            'Format',
            widget.book.bookType.toUpperCase(),
            Icons.book_outlined,
            theme,
          ),
          if (widget.book.totalPages != null)
            _buildMetadataRow(
              'Pages',
              '${widget.book.totalPages} pages',
              Icons.description_outlined,
              theme,
            ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _openBook(BuildContext context) {
    final viewModel = _bookDetailsViewModel!;

    if (!viewModel.canOpenBook()) {
      _showErrorSnackBar(
        'Book file not available. Please download the book first.',
      );
      return;
    }

    // Navigate to the ebook reader
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EbookReaderScreen(book: viewModel.currentBook!),
      ),
    ).then((_) async {
      // Refresh book data when returning from reader
      await viewModel.refreshBookData();
    });
  }

  void _showRemoveDownloadDialog(BookDetailsViewModel viewModel) async {
    final confirmed = await _showConfirmationDialog(
      'Remove Download',
      'Are you sure you want to remove the downloaded file? You can download it again later.',
    );

    if (confirmed == true) {
      await viewModel.removeDownload();
    }
  }

  void _shareBook() {
    _showInfoSnackBar('Sharing book...');
    // Implement share functionality
  }

  Future<bool?> _showConfirmationDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
