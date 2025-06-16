import 'package:flutter/foundation.dart';
import '../model/library_model.dart';
import 'library_viewmodel.dart';

class BookDetailsViewModel extends ChangeNotifier {
  final LibraryViewModel _libraryViewModel;

  // State variables
  LibraryBook? _currentBook;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _showFullDescription = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _successMessage;

  BookDetailsViewModel(this._libraryViewModel, LibraryBook initialBook) {
    _currentBook = initialBook;
  }

  // Getters
  LibraryBook? get currentBook => _currentBook;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  bool get showFullDescription => _showFullDescription;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // Toggle description visibility
  void toggleDescription() {
    _showFullDescription = !_showFullDescription;
    notifyListeners();
  }

  // Download book
  Future<void> downloadBook() async {
    if (_currentBook?.downloadUrl == null ||
        _currentBook!.downloadUrl!.isEmpty) {
      _setError('Download URL not available for this book');
      return;
    }

    _setDownloadState(true, 0.0);

    try {
      // Create a safe filename
      final fileName =
          '${_currentBook!.title.replaceAll(RegExp(r'[^\w\s]+'), '')}_${_currentBook!.id}.pdf';

      // Download the book using the LibraryViewModel
      final localPath = await _libraryViewModel.downloadBook(
        libraryBookId: _currentBook!.id,
        downloadUrl: _currentBook!.downloadUrl!,
        fileName: fileName,
        onProgress: _updateDownloadProgress,
      );

      // Update the current book state
      _currentBook = _currentBook!.copyWith(
        isDownloaded: true,
        localFilePath: localPath,
      );

      // Refresh from database to get latest state
      await refreshBookData();

      _setSuccess('Book downloaded successfully!');
    } catch (e) {
      _setError('Failed to download book: $e');
    } finally {
      _setDownloadState(false, 0.0);
    }
  }

  // Update download progress
  void _updateDownloadProgress(double progress) {
    debugPrint('Download progress: ${(progress * 100).toStringAsFixed(1)}%');
    _downloadProgress = progress;
    notifyListeners();
  }

  // Remove download
  Future<void> removeDownload() async {
    try {
      await _libraryViewModel.removeDownload(_currentBook!.id);
      await refreshBookData();
      _setSuccess('Download removed successfully');
    } catch (e) {
      _setError('Failed to remove download: $e');
    }
  }

  // Refresh book data from database
  Future<void> refreshBookData() async {
    if (_isRefreshing || _currentBook == null) return;

    _setRefreshState(true);

    try {
      final updatedBook = await _libraryViewModel.getLibraryBook(
        _currentBook!.id,
      );
      if (updatedBook != null) {
        _currentBook = updatedBook;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing book data: $e');
      _setError('Failed to refresh book data');
    } finally {
      _setRefreshState(false);
    }
  }

  // Check if book can be opened
  bool canOpenBook() {
    return _currentBook?.localFilePath != null &&
        _currentBook!.localFilePath!.isNotEmpty &&
        _currentBook!.isDownloaded;
  }

  // Get reading progress data
  Map<String, dynamic> getReadingProgressData() {
    if (_currentBook == null ||
        _currentBook!.totalPages == null ||
        _currentBook!.totalPages == 0) {
      return {'hasProgress': false};
    }

    final progress = _currentBook!.readingProgress;
    final currentPage = _currentBook!.currentPage ?? 0;
    final totalPages = _currentBook!.totalPages!;

    return {
      'hasProgress': true,
      'progress': progress,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'isCompleted': _currentBook!.isCompleted,
      'lastReadDate': _currentBook!.lastReadDate,
    };
  }

  // Get book metadata
  Map<String, String> getBookMetadata() {
    if (_currentBook == null) return {};

    return {
      'purchaseDate': _formatDate(_currentBook!.purchaseDate),
      'purchasePrice': 'RM ${_currentBook!.purchasePrice.toStringAsFixed(2)}',
      'isbn': _currentBook!.isbn ?? 'N/A',
      'bookType': _currentBook!.bookType.toUpperCase(),
      'totalPages': _currentBook!.totalPages?.toString() ?? 'Unknown',
    };
  }

  // Format date helper
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

  // Set download state
  void _setDownloadState(bool isDownloading, double progress) {
    _isDownloading = isDownloading;
    _downloadProgress = progress;
    notifyListeners();
  }

  // Set refresh state
  void _setRefreshState(bool isRefreshing) {
    _isRefreshing = isRefreshing;
    notifyListeners();
  }

  // Set error message
  void _setError(String message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  // Set success message
  void _setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
