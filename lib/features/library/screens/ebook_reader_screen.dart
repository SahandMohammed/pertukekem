import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path/path.dart' as path;
import '../models/library_model.dart';
import '../viewmodels/library_viewmodel.dart';

class EbookReaderScreen extends StatefulWidget {
  final LibraryBook book;

  const EbookReaderScreen({super.key, required this.book});

  @override
  State<EbookReaderScreen> createState() => _EbookReaderScreenState();
}

class _EbookReaderScreenState extends State<EbookReaderScreen> {
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _showAppBar = true;
  bool _fileExists = false;
  bool _fileCheckComplete = false;
  PDFViewController? _pdfController;
  late final String _fileExtension;
  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.currentPage ?? 1;
    _totalPages = widget.book.totalPages ?? 0;
    _fileExtension = widget.book.localFilePath != null ? 
        path.extension(widget.book.localFilePath!).toLowerCase() : '';

    // Hide status bar for immersive reading
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Check file existence once
    _checkFileExistence();
  }
  @override
  void dispose() {
    // Restore status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _checkFileExistence() async {
    if (widget.book.localFilePath == null || widget.book.localFilePath!.isEmpty) {
      setState(() {
        _fileExists = false;
        _fileCheckComplete = true;
      });
      return;
    }
    
    try {
      final file = File(widget.book.localFilePath!);
      final exists = await file.exists();
      setState(() {
        _fileExists = exists;
        _fileCheckComplete = true;
      });
    } catch (e) {
      setState(() {
        _fileExists = false;
        _fileCheckComplete = true;
      });
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // Update reading progress in the library
    _updateReadingProgress();
  }

  Future<void> _updateReadingProgress() async {
    if (widget.book.id.isNotEmpty && _totalPages > 0) {
      final viewModel = context.read<LibraryViewModel>();
      await viewModel.updateReadingProgress(
        libraryBookId: widget.book.id,
        currentPage: _currentPage,
        isCompleted: _currentPage >= _totalPages,
      );
    }
  }

  void _toggleAppBarVisibility() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
  }

  void _goToPage() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _currentPage.toString());
        return AlertDialog(
          title: const Text('Go to Page'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Page Number (1-$_totalPages)',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final page = int.tryParse(controller.text);
                if (page != null && page >= 1 && page <= _totalPages) {
                  _pdfController?.setPage(page - 1); // PDF pages are 0-indexed
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a valid page number (1-$_totalPages)',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }

  void _showBookmarkDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bookmark'),
            content: Text('Bookmark added for page $_currentPage'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.book.localFilePath == null ||
        !File(widget.book.localFilePath!).existsSync()) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Book file not found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'The book file needs to be downloaded first.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final fileExtension = widget.book.localFilePath!.toLowerCase();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar:
          _showAppBar
              ? AppBar(
                backgroundColor: Colors.black.withOpacity(0.7),
                foregroundColor: Colors.white,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.book.title,
                      style: const TextStyle(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Page $_currentPage of $_totalPages',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.bookmark_add),
                    onPressed: _showBookmarkDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _goToPage,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'settings':
                          _showReaderSettings();
                          break;
                        case 'info':
                          _showBookInfo();
                          break;
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'settings',
                            child: Row(
                              children: [
                                Icon(Icons.settings),
                                SizedBox(width: 8),
                                Text('Reader Settings'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'info',
                            child: Row(
                              children: [
                                Icon(Icons.info),
                                SizedBox(width: 8),
                                Text('Book Info'),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              )
              : null,      body: GestureDetector(
        onTap: _toggleAppBarVisibility,
        child: Stack(
          children: [
            if (_fileExtension.endsWith('.pdf'))
              _buildPDFReader()
            else
              _buildUnsupportedFormat(),

            // Reading progress indicator
            if (_showAppBar)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '${((_currentPage / _totalPages) * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value:
                                  _totalPages > 0
                                      ? _currentPage / _totalPages
                                      : 0,
                              backgroundColor: Colors.grey.shade600,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_currentPage/$_totalPages',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }  Widget _buildPDFReader() {
    // Show loading while checking file existence
    if (!_fileCheckComplete) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Check if file exists
    if (!_fileExists) {
      return _buildFileNotAvailable();
    }        return Stack(
          children: [
            RepaintBoundary(
              child: PDFView(
                key: ValueKey(widget.book.localFilePath),
                filePath: widget.book.localFilePath!,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: true,
                pageFling: true,
                pageSnap: true,
                defaultPage: (_currentPage - 1).clamp(0, _totalPages - 1),
                fitPolicy: FitPolicy.BOTH,
                preventLinkNavigation: false,
                onRender: (pages) {
                  if (mounted) {
                    setState(() {
                      _totalPages = pages ?? 0;
                      _isLoading = false;
                    });
                  }
                },
                onError: (error) {
                  debugPrint('PDF Error: $error');
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                onPageError: (page, error) {
                  debugPrint('PDF Page Error: $error');
                },
                onViewCreated: (PDFViewController controller) {
                  if (mounted) {
                    setState(() {
                      _pdfController = controller;
                    });
                  }
                },
                onPageChanged: (page, total) {
                  if (mounted) {
                    _onPageChanged((page ?? 0) + 1); // Convert to 1-indexed
                  }
                },
              ),
            ),
            // Loading indicator
            if (_isLoading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
      ],
    );
  }

  Widget _buildFileNotAvailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.download_rounded,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'File Not Available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This book needs to be downloaded first before it can be read.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Go back to library
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Library'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupportedFormat() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            'Unsupported Format',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Currently only PDF files are supported for reading.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showReaderSettings() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reader Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Display Mode'),
                  subtitle: const Text('Day mode'),
                  onTap: () {
                    // TODO: Implement display mode settings
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: const Text('Text Size'),
                  subtitle: const Text('Medium'),
                  onTap: () {
                    // TODO: Implement text size settings
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.auto_stories),
                  title: const Text('Page Transition'),
                  subtitle: const Text('Slide'),
                  onTap: () {
                    // TODO: Implement page transition settings
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showBookInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Book Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Title', widget.book.title),
                _buildInfoRow('Author', widget.book.author),
                if (widget.book.isbn != null)
                  _buildInfoRow('ISBN', widget.book.isbn!),
                _buildInfoRow('Type', widget.book.bookType),
                _buildInfoRow('Total Pages', _totalPages.toString()),
                _buildInfoRow('Current Page', _currentPage.toString()),
                _buildInfoRow(
                  'Progress',
                  '${((_currentPage / _totalPages) * 100).toInt()}%',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
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
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
