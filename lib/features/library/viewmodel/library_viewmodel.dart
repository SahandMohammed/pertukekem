import 'package:flutter/foundation.dart';
import '../../../core/interfaces/state_clearable.dart';
import '../model/library_model.dart';
import '../service/library_service.dart';
import '../notifiers/library_notifier.dart';

class LibraryViewModel extends ChangeNotifier implements StateClearable {
  final LibraryService _libraryService = LibraryService();
  final LibraryNotifier _libraryNotifier = LibraryNotifier();

  LibraryViewModel() {
    _libraryNotifier.addListener(_onLibraryChanged);
  }

  @override
  void dispose() {
    _libraryNotifier.removeListener(_onLibraryChanged);
    super.dispose();
  }

  void _onLibraryChanged() {
    if (kDebugMode) {
      print('LibraryViewModel: Library changed, refreshing data');
    }
    if (!_isLoadingLibrary && !_isLoadingStats && !_isLoadingCurrentlyReading) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_isLoadingLibrary) {
          refreshAll();
        }
      });
    }
  }

  List<LibraryBook> _allBooks = [];
  List<LibraryBook> _ebooks = [];
  List<LibraryBook> _physicalBooks = [];
  List<LibraryBook> _currentlyReading = [];
  List<LibraryBook> _recentlyPurchased = [];
  LibraryStats? _stats;

  bool _isLoadingLibrary = false;
  bool _isLoadingStats = false;
  bool _isLoadingCurrentlyReading = false;

  String? _errorMessage;

  String _searchQuery = '';
  String _currentFilter = 'all'; // 'all', 'ebooks', 'physical'

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

  Future<bool> checkBookOwnership(String bookId) async {
    try {
      return await _libraryService.userOwnsBook(bookId);
    } catch (e) {
      debugPrint('Error checking book ownership: $e');
      return false;
    }
  }

  Future<LibraryBook?> getLibraryBook(String bookId) async {
    try {
      return await _libraryService.getLibraryBook(bookId);
    } catch (e) {
      debugPrint('Error getting library book: $e');
      return null;
    }
  }

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

      await loadCurrentlyReading();
      await loadLibrary();
    } catch (e) {
      _errorMessage = 'Failed to update reading progress: $e';
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

  Future<void> markBookAsDownloaded({
    required String libraryBookId,
    required String localFilePath,
  }) async {
    try {
      await _libraryService.markAsDownloaded(
        libraryBookId: libraryBookId,
        localFilePath: localFilePath,
      );

      await loadLibrary();
    } catch (e) {
      _errorMessage = 'Failed to mark book as downloaded: $e';
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

  Future<void> removeDownload(String libraryBookId) async {
    try {
      await _libraryService.removeDownload(libraryBookId);

      await loadLibrary();
    } catch (e) {
      _errorMessage = 'Failed to remove download: $e';
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

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

      await loadLibrary();

      return filePath;
    } catch (e) {
      _errorMessage = 'Failed to download book: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      rethrow;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await Future.wait([loadLibrary(), loadCurrentlyReading(), loadStats()]);
  }

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

      await loadLibrary();
      await loadStats();
    } catch (e) {
      _errorMessage = 'Failed to add book to library: $e';
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  Future<void> clearState() async {
    _allBooks.clear();
    _ebooks.clear();
    _physicalBooks.clear();
    _currentlyReading.clear();
    _recentlyPurchased.clear();

    _stats = null;

    _isLoadingLibrary = false;
    _isLoadingStats = false;
    _isLoadingCurrentlyReading = false;

    _errorMessage = null;

    _searchQuery = '';
    _currentFilter = 'all';

    notifyListeners();
  }
}
