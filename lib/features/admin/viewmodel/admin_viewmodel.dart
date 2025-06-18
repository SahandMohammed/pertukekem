import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/interfaces/state_clearable.dart';
import '../model/admin_user_model.dart';
import '../model/admin_store_model.dart';
import '../model/admin_listing_model.dart';
import '../services/admin_service.dart';

class AdminViewModel extends ChangeNotifier implements StateClearable {
  final AdminService _adminService = AdminService();

  // Loading states
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  bool _isLoadingStores = false;
  bool _isLoadingListings = false;
  bool _isLoadingStats = false;

  // Data
  List<AdminUserModel> _users = [];
  List<AdminStoreModel> _stores = [];
  List<AdminListingModel> _listings = [];
  Map<String, int> _statistics = {};

  // Pagination
  DocumentSnapshot? _lastUserDoc;
  DocumentSnapshot? _lastStoreDoc;
  DocumentSnapshot? _lastListingDoc;
  bool _hasMoreUsers = true;
  bool _hasMoreStores = true;
  bool _hasMoreListings = true;

  // Search
  List<AdminUserModel> _searchedUsers = [];
  List<AdminStoreModel> _searchedStores = [];
  List<AdminListingModel> _searchedListings = [];
  bool _isSearchMode = false;
  String _currentSearchTerm = '';

  // Error handling
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingUsers => _isLoadingUsers;
  bool get isLoadingStores => _isLoadingStores;
  bool get isLoadingListings => _isLoadingListings;
  bool get isLoadingStats => _isLoadingStats;

  List<AdminUserModel> get users => _isSearchMode ? _searchedUsers : _users;
  List<AdminStoreModel> get stores => _isSearchMode ? _searchedStores : _stores;
  List<AdminListingModel> get listings =>
      _isSearchMode ? _searchedListings : _listings;
  Map<String, int> get statistics => _statistics;

  bool get hasMoreUsers => _hasMoreUsers && !_isSearchMode;
  bool get hasMoreStores => _hasMoreStores && !_isSearchMode;
  bool get hasMoreListings => _hasMoreListings && !_isSearchMode;

  bool get isSearchMode => _isSearchMode;
  String get currentSearchTerm => _currentSearchTerm;
  String? get errorMessage => _errorMessage;
  @override
  Future<void> clearState() async {
    _users.clear();
    _stores.clear();
    _listings.clear();
    _statistics.clear();
    _searchedUsers.clear();
    _searchedStores.clear();
    _searchedListings.clear();

    _lastUserDoc = null;
    _lastStoreDoc = null;
    _lastListingDoc = null;

    _hasMoreUsers = true;
    _hasMoreStores = true;
    _hasMoreListings = true;

    _isSearchMode = false;
    _currentSearchTerm = '';
    _errorMessage = null;

    _isLoading = false;
    _isLoadingUsers = false;
    _isLoadingStores = false;
    _isLoadingListings = false;
    _isLoadingStats = false;

    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Statistics
  Future<void> loadStatistics() async {
    if (_isLoadingStats) return;

    _isLoadingStats = true;
    notifyListeners();

    try {
      _statistics = await _adminService.getStatistics();
      _errorMessage = null;
    } catch (e) {
      _setError('Failed to load statistics: ${e.toString()}');
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  // Users Management
  Future<void> loadUsers({bool refresh = false}) async {
    if (_isLoadingUsers) return;

    if (refresh) {
      _users.clear();
      _lastUserDoc = null;
      _hasMoreUsers = true;
    }

    if (!_hasMoreUsers) return;

    _isLoadingUsers = true;
    notifyListeners();

    try {
      final users = await _adminService.getAllUsers(startAfter: _lastUserDoc);

      if (users.isNotEmpty) {
        _users.addAll(users);
        // Note: We can't get the last document easily with our current model
        // This is a limitation we'll accept for now
        _hasMoreUsers = users.length == 20; // Assume no more if less than limit
      } else {
        _hasMoreUsers = false;
      }

      _errorMessage = null;
    } catch (e) {
      _setError('Failed to load users: ${e.toString()}');
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> toggleUserBlock(String userId, bool isBlocked) async {
    try {
      await _adminService.toggleUserBlock(userId, isBlocked);

      // Update local data
      final userIndex = _users.indexWhere((user) => user.userId == userId);
      if (userIndex != -1) {
        _users[userIndex] = AdminUserModel(
          userId: _users[userIndex].userId,
          firstName: _users[userIndex].firstName,
          lastName: _users[userIndex].lastName,
          email: _users[userIndex].email,
          phoneNumber: _users[userIndex].phoneNumber,
          roles: _users[userIndex].roles,
          isBlocked: isBlocked,
          isEmailVerified: _users[userIndex].isEmailVerified,
          isPhoneVerified: _users[userIndex].isPhoneVerified,
          createdAt: _users[userIndex].createdAt,
          lastLoginAt: _users[userIndex].lastLoginAt,
          profilePicture: _users[userIndex].profilePicture,
          storeId: _users[userIndex].storeId,
          storeName: _users[userIndex].storeName,
        );
      }

      // Update search results if in search mode
      if (_isSearchMode) {
        final searchUserIndex = _searchedUsers.indexWhere(
          (user) => user.userId == userId,
        );
        if (searchUserIndex != -1) {
          _searchedUsers[searchUserIndex] = AdminUserModel(
            userId: _searchedUsers[searchUserIndex].userId,
            firstName: _searchedUsers[searchUserIndex].firstName,
            lastName: _searchedUsers[searchUserIndex].lastName,
            email: _searchedUsers[searchUserIndex].email,
            phoneNumber: _searchedUsers[searchUserIndex].phoneNumber,
            roles: _searchedUsers[searchUserIndex].roles,
            isBlocked: isBlocked,
            isEmailVerified: _searchedUsers[searchUserIndex].isEmailVerified,
            isPhoneVerified: _searchedUsers[searchUserIndex].isPhoneVerified,
            createdAt: _searchedUsers[searchUserIndex].createdAt,
            lastLoginAt: _searchedUsers[searchUserIndex].lastLoginAt,
            profilePicture: _searchedUsers[searchUserIndex].profilePicture,
            storeId: _searchedUsers[searchUserIndex].storeId,
            storeName: _searchedUsers[searchUserIndex].storeName,
          );
        }
      }

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update user status: ${e.toString()}');
    }
  }

  Future<void> searchUsers(String searchTerm) async {
    if (searchTerm.isEmpty) {
      _isSearchMode = false;
      _currentSearchTerm = '';
      _searchedUsers.clear();
      notifyListeners();
      return;
    }

    _isSearchMode = true;
    _currentSearchTerm = searchTerm;
    _isLoadingUsers = true;
    notifyListeners();

    try {
      _searchedUsers = await _adminService.searchUsers(searchTerm);
      _errorMessage = null;
    } catch (e) {
      _setError('Failed to search users: ${e.toString()}');
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  // Stores Management
  Future<void> loadStores({bool refresh = false}) async {
    if (_isLoadingStores) return;

    if (refresh) {
      _stores.clear();
      _lastStoreDoc = null;
      _hasMoreStores = true;
    }

    if (!_hasMoreStores) return;

    _isLoadingStores = true;
    notifyListeners();

    try {
      final stores = await _adminService.getAllStores(
        startAfter: _lastStoreDoc,
      );

      if (stores.isNotEmpty) {
        _stores.addAll(stores);
        _hasMoreStores = stores.length == 20;
      } else {
        _hasMoreStores = false;
      }

      _errorMessage = null;
    } catch (e) {
      _setError('Failed to load stores: ${e.toString()}');
    } finally {
      _isLoadingStores = false;
      notifyListeners();
    }
  }

  Future<void> toggleStoreBlock(
    String storeId,
    String ownerId,
    bool isBlocked,
  ) async {
    try {
      await _adminService.toggleStoreBlock(storeId, ownerId, isBlocked);

      // Update local data
      final storeIndex = _stores.indexWhere(
        (store) => store.storeId == storeId,
      );
      if (storeIndex != -1) {
        _stores[storeIndex] = AdminStoreModel(
          storeId: _stores[storeIndex].storeId,
          ownerId: _stores[storeIndex].ownerId,
          storeName: _stores[storeIndex].storeName,
          description: _stores[storeIndex].description,
          ownerName: _stores[storeIndex].ownerName,
          ownerEmail: _stores[storeIndex].ownerEmail,
          isVerified: _stores[storeIndex].isVerified,
          isBlocked: isBlocked,
          rating: _stores[storeIndex].rating,
          totalRatings: _stores[storeIndex].totalRatings,
          createdAt: _stores[storeIndex].createdAt,
          logoUrl: _stores[storeIndex].logoUrl,
          categories: _stores[storeIndex].categories,
          totalListings: _stores[storeIndex].totalListings,
        );
      }

      // Update search results if in search mode
      if (_isSearchMode) {
        final searchStoreIndex = _searchedStores.indexWhere(
          (store) => store.storeId == storeId,
        );
        if (searchStoreIndex != -1) {
          _searchedStores[searchStoreIndex] = AdminStoreModel(
            storeId: _searchedStores[searchStoreIndex].storeId,
            ownerId: _searchedStores[searchStoreIndex].ownerId,
            storeName: _searchedStores[searchStoreIndex].storeName,
            description: _searchedStores[searchStoreIndex].description,
            ownerName: _searchedStores[searchStoreIndex].ownerName,
            ownerEmail: _searchedStores[searchStoreIndex].ownerEmail,
            isVerified: _searchedStores[searchStoreIndex].isVerified,
            isBlocked: isBlocked,
            rating: _searchedStores[searchStoreIndex].rating,
            totalRatings: _searchedStores[searchStoreIndex].totalRatings,
            createdAt: _searchedStores[searchStoreIndex].createdAt,
            logoUrl: _searchedStores[searchStoreIndex].logoUrl,
            categories: _searchedStores[searchStoreIndex].categories,
            totalListings: _searchedStores[searchStoreIndex].totalListings,
          );
        }
      }

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update store status: ${e.toString()}');
    }
  }

  Future<void> searchStores(String searchTerm) async {
    if (searchTerm.isEmpty) {
      _isSearchMode = false;
      _currentSearchTerm = '';
      _searchedStores.clear();
      notifyListeners();
      return;
    }

    _isSearchMode = true;
    _currentSearchTerm = searchTerm;
    _isLoadingStores = true;
    notifyListeners();

    try {
      _searchedStores = await _adminService.searchStores(searchTerm);
      _errorMessage = null;
    } catch (e) {
      _setError('Failed to search stores: ${e.toString()}');
    } finally {
      _isLoadingStores = false;
      notifyListeners();
    }
  }

  // Listings Management
  Future<void> loadListings({bool refresh = false}) async {
    if (_isLoadingListings) return;

    if (refresh) {
      _listings.clear();
      _lastListingDoc = null;
      _hasMoreListings = true;
    }

    if (!_hasMoreListings) return;

    _isLoadingListings = true;
    notifyListeners();

    try {
      final listings = await _adminService.getAllListings(
        startAfter: _lastListingDoc,
      );

      if (listings.isNotEmpty) {
        _listings.addAll(listings);
        _hasMoreListings = listings.length == 20;
      } else {
        _hasMoreListings = false;
      }

      _errorMessage = null;
    } catch (e) {
      _setError('Failed to load listings: ${e.toString()}');
    } finally {
      _isLoadingListings = false;
      notifyListeners();
    }
  }

  Future<void> removeListing(String listingId) async {
    try {
      await _adminService.removeListing(listingId);

      // Update local data
      final listingIndex = _listings.indexWhere(
        (listing) => listing.id == listingId,
      );
      if (listingIndex != -1) {
        _listings[listingIndex] = AdminListingModel(
          id: _listings[listingIndex].id,
          title: _listings[listingIndex].title,
          author: _listings[listingIndex].author,
          price: _listings[listingIndex].price,
          condition: _listings[listingIndex].condition,
          sellerType: _listings[listingIndex].sellerType,
          sellerId: _listings[listingIndex].sellerId,
          sellerName: _listings[listingIndex].sellerName,
          status: 'removed',
          coverUrl: _listings[listingIndex].coverUrl,
          createdAt: _listings[listingIndex].createdAt,
          bookType: _listings[listingIndex].bookType,
          category: _listings[listingIndex].category,
        );
      }

      // Update search results if in search mode
      if (_isSearchMode) {
        final searchListingIndex = _searchedListings.indexWhere(
          (listing) => listing.id == listingId,
        );
        if (searchListingIndex != -1) {
          _searchedListings[searchListingIndex] = AdminListingModel(
            id: _searchedListings[searchListingIndex].id,
            title: _searchedListings[searchListingIndex].title,
            author: _searchedListings[searchListingIndex].author,
            price: _searchedListings[searchListingIndex].price,
            condition: _searchedListings[searchListingIndex].condition,
            sellerType: _searchedListings[searchListingIndex].sellerType,
            sellerId: _searchedListings[searchListingIndex].sellerId,
            sellerName: _searchedListings[searchListingIndex].sellerName,
            status: 'removed',
            coverUrl: _searchedListings[searchListingIndex].coverUrl,
            createdAt: _searchedListings[searchListingIndex].createdAt,
            bookType: _searchedListings[searchListingIndex].bookType,
            category: _searchedListings[searchListingIndex].category,
          );
        }
      }

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove listing: ${e.toString()}');
    }
  }

  Future<void> searchListings(String searchTerm) async {
    if (searchTerm.isEmpty) {
      _isSearchMode = false;
      _currentSearchTerm = '';
      _searchedListings.clear();
      notifyListeners();
      return;
    }

    _isSearchMode = true;
    _currentSearchTerm = searchTerm;
    _isLoadingListings = true;
    notifyListeners();

    try {
      _searchedListings = await _adminService.searchListings(searchTerm);
      _errorMessage = null;
    } catch (e) {
      _setError('Failed to search listings: ${e.toString()}');
    } finally {
      _isLoadingListings = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _isSearchMode = false;
    _currentSearchTerm = '';
    _searchedUsers.clear();
    _searchedStores.clear();
    _searchedListings.clear();
    notifyListeners();
  }
}
