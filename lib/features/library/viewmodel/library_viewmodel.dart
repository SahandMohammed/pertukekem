import 'package:flutter/foundation.dart';
import '../../../core/interfaces/state_clearable.dart';
import '../model/library_model.dart';
import '../service/library_service.dart';
import '../notifiers/library_notifier.dart';

class LibraryViewModel extends ChangeNotifier implements StateClearable {
  final LibraryService _libraryService = LibraryService();
  final LibraryNotifier _libraryNotifier = LibraryNotifier();

  // Constructor to set up listeners
  LibraryViewModel() {
    _libraryNotifier.addListener(_onLibraryChanged);
  }

  @override
  void dispose() {
    _libraryNotifier.removeListener(_onLibraryChanged);
    super.dispose();
  }

  // Handle library change notifications
  void _onLibraryChanged() {
    if (kDebugMode) {
      print('LibraryViewModel: Library changed, refreshing data');
    }
    // Only refresh if not currently loading to prevent multiple concurrent refreshes
    if (!_isLoadingLibrary && !_isLoadingStats && !_isLoadingCurrentlyReading) {
      Future.delayed(const Duration(milliseconds: 300), () {
        // Small delay to batch rapid changes
        if (!_isLoadingLibrary) {
          refreshAll();
        }
      });
    }
  }

  // State variables
  List<LibraryBook> _allBooks = [];
  List<LibraryBook> _ebooks = [];
  List<LibraryBook> _physicalBooks = [];
  List<LibraryBook> _currentlyReading = [];
  List<LibraryBook> _recentlyPurchased = [];
  LibraryStats? _stats;

  // Loading states
  bool _isLoadingLibrary = false;
  bool _isLoadingStats = false;
  bool _isLoadingCurrentlyReading = false;

  // Error states
  String? _errorMessage;

  // Filter and search
  String _searchQuery = '';
  String _currentFilter = 'all'; // 'all', 'ebooks', 'physical'

  // Getters
  List<LibraryBook> get allBooks => _allBooks;
  List<LibraryBook> get ebooks => _ebooks;
  List<LibraryBook> get physicalBooks => _physicalBooks;
  List<LibraryBook> get currentlyReading => _currentlyReading;
  List<LibraryBook> get recentlyPurchased => _recentlyPurchased;
  LibraryStats? get stats => _stats;

  bool get isLoadingLibrary => _isLoadingLibrary;
  bool get isLoadingStats => _isLoadingStats;
  bool get isLoadingCurrentlyReading => _isLoadingCurrentlyReading;

  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get currentFilter => _currentFilter;

  // Get filtered books based on current filter
  List<LibraryBook> get filteredBooks {
    List<LibraryBook> books;
    switch (_currentFilter) {
      case 'ebooks':
        books = _ebooks;
        break;
      case 'physical':
        books = _physicalBooks;
        break;
      default:
        books = _allBooks;
    }

    if (_searchQuery.isEmpty) {
      return books;
    }

    final lowercaseQuery = _searchQuery.toLowerCase();
    return books.where((book) {
      return book.title.toLowerCase().contains(lowercaseQuery) ||
          book.author.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Load user's complete library
  Future<void> loadLibrary() async {
    _isLoadingLibrary = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allBooks = await _libraryService.getUserLibrary();
      _ebooks = await _libraryService.getEbooks();
      _physicalBooks = await _libraryService.getPhysicalBooks();
      _recentlyPurchased = await _libraryService.getRecentlyPurchased(limit: 5);
    } catch (e) {
      _errorMessage = 'Failed to load library: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoadingLibrary = false;
      notifyListeners();
    }
  }

  // Load currently reading books
  Future<void> loadCurrentlyReading() async {
    _isLoadingCurrentlyReading = true;
    notifyListeners();

    try {
      _currentlyReading = await _libraryService.getCurrentlyReading(limit: 5);
    } catch (e) {
      _errorMessage = 'Failed to load currently reading: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoadingCurrentlyReading = false;
      notifyListeners();
    }
  }

  // Load library statistics
  Future<void> loadStats() async {
    _isLoadingStats = true;
    notifyListeners();

    try {
      _stats = await _libraryService.getLibraryStats();
    } catch (e) {
      _errorMessage = 'Failed to load stats: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  // Check if user owns a book
  Future<bool> checkBookOwnership(String bookId) async {
    try {
      return await _libraryService.userOwnsBook(bookId);
    } catch (e) {
      debugPrint('Error checking book ownership: $e');
      return false;
    }
  }

  // Get specific library book
  Future<LibraryBook?> getLibraryBook(String bookId) async {
    try {
      return await _libraryService.getLibraryBook(bookId);
    } catch (e) {
      debugPrint('Error getting library book: $e');
      return null;
    }
  }

  // Update reading progress
  Future<void> updateReadingProgress({
    required String libraryBookId,
    required int currentPage,
    bool? isCompleted,
  }) async {
    try {
      await _libraryService.updateReadingProgress(
        libraryBookId: libraryBookId,
        currentPage: currentPage,
        isCompleted: isCompleted,
      );

      // Reload data to reflect changes
      await loadCurrentlyReading();
      await loadLibrary();
    } catch (e) {
      _errorMessage = 'Failed to update reading progress: $e';
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

  // Mark book as downloaded
  Future<void> markBookAsDownloaded({
    required String libraryBookId,
    required String localFilePath,
  }) async {
    try {
      await _libraryService.markAsDownloaded(
        libraryBookId: libraryBookId,
        localFilePath: localFilePath,
      );

      // Reload library to reflect changes
      await loadLibrary();
    } catch (e) {
      _errorMessage = 'Failed to mark book as downloaded: $e';
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

  // Remove download
  Future<void> removeDownload(String libraryBookId) async {
    try {
      await _libraryService.removeDownload(libraryBookId);

      // Reload library to reflect changes
      await loadLibrary();
    } catch (e) {
      _errorMessage = 'Failed to remove download: $e';
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

  // Download book
  Future<String> downloadBook({
    required String libraryBookId,
    required String downloadUrl,
    required String fileName,
    required Function(double) onProgress,
  }) async {
    try {
      final filePath = await _libraryService.downloadBook(
        libraryBookId: libraryBookId,
        downloadUrl: downloadUrl,
        fileName: fileName,
        onProgress: onProgress,
      );

      // Reload library to reflect changes
      await loadLibrary();

      return filePath;
    } catch (e) {
      _errorMessage = 'Failed to download book: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      rethrow;
    }
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Set filter
  void setFilter(String filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([loadLibrary(), loadCurrentlyReading(), loadStats()]);
  }

  // Add book to library (called after purchase)
  Future<void> addBookToLibrary({
    required String userId,
    required dynamic listing, // Listing
    required DateTime purchaseDate,
    String? orderId,
    String? transactionId,
  }) async {
    try {
      await _libraryService.addBookToLibrary(
        userId: userId,
        listing: listing,
        purchaseDate: purchaseDate,
        orderId: orderId,
        transactionId: transactionId,
      );

      // Reload library after adding book
      await loadLibrary();
      await loadStats();
    } catch (e) {
      _errorMessage = 'Failed to add book to library: $e';
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  Future<void> clearState() async {
    // Clear all book lists
    _allBooks.clear();
    _ebooks.clear();
    _physicalBooks.clear();
    _currentlyReading.clear();
    _recentlyPurchased.clear();

    // Clear stats
    _stats = null;

    // Reset loading states
    _isLoadingLibrary = false;
    _isLoadingStats = false;
    _isLoadingCurrentlyReading = false;

    // Clear error state
    _errorMessage = null;

    // Reset filter and search
    _searchQuery = '';
    _currentFilter = 'all';

    notifyListeners();
  }
}
