import 'package:flutter/material.dart';
import '../../../listings/model/listing_model.dart';
import '../../store/models/store_model.dart';
import '../services/customer_home_service.dart';

class CustomerHomeViewModel extends ChangeNotifier {
  final CustomerHomeService _homeService = CustomerHomeService();

  // Recently listed items
  List<Listing> _recentlyListedItems = [];
  List<Listing> get recentlyListedItems => _recentlyListedItems;

  // Recently joined stores
  List<StoreModel> _recentlyJoinedStores = [];
  List<StoreModel> get recentlyJoinedStores => _recentlyJoinedStores;

  // All stores
  List<StoreModel> _allStores = [];
  List<StoreModel> get allStores => _allStores;

  // Search results
  List<Listing> _searchResults = [];
  List<Listing> get searchResults => _searchResults;

  // Loading states
  bool _isLoadingRecentItems = false;
  bool get isLoadingRecentItems => _isLoadingRecentItems;

  bool _isLoadingRecentStores = false;
  bool get isLoadingRecentStores => _isLoadingRecentStores;

  bool _isLoadingAllStores = false;
  bool get isLoadingAllStores => _isLoadingAllStores;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  // Error states
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Search query
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Load recently listed items
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

  /// Load recently joined stores
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

  /// Load all stores
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

  /// Search for listings
  Future<void> searchListings(String query) async {
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
      _searchResults = await _homeService.searchListings(_searchQuery);
    } catch (e) {
      _errorMessage = 'Search failed: $e';
      debugPrint(_errorMessage);
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([loadRecentlyListedItems(), loadRecentlyJoinedStores()]);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
