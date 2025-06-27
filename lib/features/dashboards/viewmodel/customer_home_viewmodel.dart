import 'package:flutter/material.dart';
import '../../../core/interfaces/state_clearable.dart';
import '../../listings/model/listing_model.dart';
import '../model/store_model.dart';
import '../service/customer_home_service.dart';
import '../../library/model/library_model.dart';
import '../../library/service/library_service.dart';

class CustomerHomeViewModel extends ChangeNotifier implements StateClearable {
  final CustomerHomeService _homeService = CustomerHomeService();
  final LibraryService _libraryService = LibraryService();

  List<Listing> _recentlyListedItems = [];
  List<Listing> get recentlyListedItems => _recentlyListedItems;

  List<StoreModel> _recentlyJoinedStores = [];
  List<StoreModel> get recentlyJoinedStores => _recentlyJoinedStores;

  List<StoreModel> _allStores = [];
  List<StoreModel> get allStores => _allStores;

  List<Listing> _searchResults = [];
  List<Listing> get searchResults => _searchResults;

  List<LibraryBook> _currentlyReadingBooks = [];
  List<LibraryBook> get currentlyReadingBooks => _currentlyReadingBooks;

  bool _isLoadingRecentItems = false;
  bool get isLoadingRecentItems => _isLoadingRecentItems;

  bool _isLoadingRecentStores = false;
  bool get isLoadingRecentStores => _isLoadingRecentStores;

  bool _isLoadingAllStores = false;
  bool get isLoadingAllStores => _isLoadingAllStores;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  bool _isLoadingCurrentlyReading = false;
  bool get isLoadingCurrentlyReading => _isLoadingCurrentlyReading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  Future<void> loadRecentlyListedItems() async {
    _isLoadingRecentItems = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recentlyListedItems = await _homeService.getRecentlyListedItems(
        limit: 10,
      );
    } catch (e) {
      _errorMessage = 'Failed to load recent items: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoadingRecentItems = false;
      notifyListeners();
    }
  }

  Future<void> loadRecentlyJoinedStores() async {
    _isLoadingRecentStores = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recentlyJoinedStores = await _homeService.getRecentlyJoinedStores(
        limit: 10,
      );
    } catch (e) {
      _errorMessage = 'Failed to load recent stores: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoadingRecentStores = false;
      notifyListeners();
    }
  }

  Future<void> loadAllStores() async {
    _isLoadingAllStores = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allStores = await _homeService.getAllStores();
    } catch (e) {
      _errorMessage = 'Failed to load stores: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoadingAllStores = false;
      notifyListeners();
    }
  }

  Future<void> searchListings(String query, {String? condition}) async {
    _searchQuery = query.trim();

    if (_searchQuery.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _homeService.searchListings(
        _searchQuery,
        condition: condition,
      );
    } catch (e) {
      _errorMessage = 'Search failed: $e';
      debugPrint(_errorMessage);
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  Future<void> loadCurrentlyReadingBooks() async {
    _isLoadingCurrentlyReading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentlyReadingBooks = await _libraryService.getCurrentlyReading(
        limit: 5,
      );
    } catch (e) {
      _errorMessage = 'Failed to load currently reading books: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoadingCurrentlyReading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadRecentlyListedItems(),
      loadRecentlyJoinedStores(),
      loadCurrentlyReadingBooks(),
    ]);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  Future<void> clearState() async {
    debugPrint('🧹 Clearing CustomerHomeViewModel state...');

    _recentlyListedItems.clear();
    _recentlyJoinedStores.clear();
    _allStores.clear();
    _searchResults.clear();
    _currentlyReadingBooks.clear();

    _isLoadingRecentItems = false;
    _isLoadingRecentStores = false;
    _isLoadingAllStores = false;
    _isSearching = false;
    _isLoadingCurrentlyReading = false;

    _errorMessage = null;
    _searchQuery = '';

    notifyListeners();

    debugPrint('✅ CustomerHomeViewModel state cleared');
  }
}
