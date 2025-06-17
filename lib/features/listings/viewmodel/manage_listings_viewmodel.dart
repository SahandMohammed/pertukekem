import 'package:flutter/material.dart';
import 'package:pertukekem/core/services/listing_service.dart';
import 'package:pertukekem/features/listings/model/listing_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/interfaces/state_clearable.dart';
import 'dart:async';

class ManageListingsViewModel extends ChangeNotifier implements StateClearable {
  final ListingService _listingService = ListingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State management
  List<Listing> _listings = [];
  StreamSubscription<List<Listing>>? _listingsSubscription;
  String _searchTerm = '';
  String get searchTerm => _searchTerm;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  // Navigation state management
  bool _hasReturnedFromNavigation = false;
  bool get hasReturnedFromNavigation => _hasReturnedFromNavigation;

  // UI state for showing messages
  String? _successMessage;
  String? get successMessage => _successMessage;

  // Getters
  List<Listing> get listings => _listings;

  // Get filtered listings based on search term
  List<Listing> get filteredListings {
    if (_searchTerm.isEmpty) {
      return _listings;
    }
    return _filterListings(_listings);
  }

  ManageListingsViewModel();

  @override
  void dispose() {
    _listingsSubscription?.cancel();
    super.dispose();
  }

  @override
  Future<void> clearState() async {
    debugPrint('🧹 Clearing ManageListingsViewModel state...');

    // Cancel subscription
    await _listingsSubscription?.cancel();
    _listingsSubscription = null;

    // Clear all state
    _listings = [];
    _searchTerm = '';
    _errorMessage = null;
    _isLoading = false;
    _isRefreshing = false;
    _hasReturnedFromNavigation = false;
    _successMessage = null;

    // Notify listeners
    notifyListeners();

    debugPrint('✅ ManageListingsViewModel state cleared');
  }

  /// Load all listings for the current seller
  Future<void> loadListings() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Cancel existing subscription
      await _listingsSubscription?.cancel();

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _errorMessage = "User not authenticated.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('Loading seller listings for user: ${currentUser.uid}');

      // Determine seller type and create seller reference
      final storeDoc =
          await _firestore.collection('stores').doc(currentUser.uid).get();

      String sellerType = storeDoc.exists ? "store" : "user";
      DocumentReference sellerRef = _firestore
          .collection(sellerType == 'store' ? 'stores' : 'users')
          .doc(currentUser.uid);

      print('Setting up listings stream with:');
      print('- sellerType: $sellerType');
      print(
        '- sellerRef: ${sellerRef.path}',
      ); // Start listening to listings stream
      _listingsSubscription = _listingService
          .watchAllListings(
            sellerRef: sellerRef,
            sellerType: sellerType,
            filterByStatus: false, // Show all listings in manage screen
          )
          .listen(
            (listings) {
              print('📦 Received ${listings.length} listings from Firestore');
              _listings = listings;
              _isLoading = false;
              _errorMessage = null;

              // Clear refreshing state when we get new data
              if (_isRefreshing) {
                _isRefreshing = false;
              }

              notifyListeners();
            },
            onError: (error) {
              print('Error in listings stream: $error');
              _errorMessage = error.toString();
              _isLoading = false;
              _isRefreshing = false;
              notifyListeners();
            },
          );
    } catch (e) {
      print('Error setting up listings stream: $e');
      _errorMessage = "Error determining seller type: $e";
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Force refresh listings from server
  Future<void> refreshListings() async {
    // Prevent multiple simultaneous refresh operations
    if (_isRefreshing) {
      print('⏳ Refresh already in progress, skipping...');
      return;
    }

    print('🔄 Refreshing listings...');
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Cancel existing subscription and reload
      await _listingsSubscription?.cancel();
      _listingsSubscription = null;

      // Reload listings
      await loadListings();

      print('✅ Listings refresh completed');
    } catch (e) {
      print('❌ Error refreshing listings: $e');
      _errorMessage = e.toString();
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void updateSearchTerm(String term) {
    _searchTerm = term.toLowerCase();
    notifyListeners();
  }

  List<Listing> _filterListings(List<Listing> listings) {
    if (_searchTerm.isEmpty) return listings;

    return listings.where((listing) {
      final searchableText = [
        listing.title.toLowerCase(),
        listing.description?.toLowerCase() ?? '',
        ...listing.category.map((cat) => cat.toLowerCase()),
      ].join(' ');

      return searchableText.contains(_searchTerm);
    }).toList();
  }

  Future<void> addListing(Listing listing) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _listingService.addListing(listing);
      // The stream will automatically update when Firestore changes are detected
      // Clear loading state
      _isLoading = false;
      _successMessage = 'Listing added successfully';
      print('✅ Listing added successfully');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      print('❌ Error adding listing: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateListing(Listing listing) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _listingService.updateListing(listing);
      // The stream will automatically update when Firestore changes are detected
      // Clear loading state
      _isLoading = false;
      _successMessage = 'Listing updated successfully';
      print('✅ Listing updated successfully');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      print('❌ Error updating listing: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteListing(String listingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _listingService.deleteListing(listingId);
      // The stream will automatically update when Firestore changes are detected
      // Clear loading state
      _isLoading = false;
      _successMessage = 'Listing deleted successfully';
      print('✅ Listing deleted successfully');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      print('❌ Error deleting listing: $e');
    } finally {
      notifyListeners();
    }
  } // Call this if you need to refresh the listings manually

  Future<void> oldRefreshListings() async {
    // This method is deprecated - use refreshListings() instead
    await refreshListings();
  }

  // Public method to reinitialize the stream (useful after auth state changes)
  void reinitializeStream() {
    debugPrint('🔄 Manually reinitializing ManageListingsViewModel stream...');
    loadListings();
  }

  // Navigation and UI state management methods
  void navigateToListingDetail(BuildContext context, Listing listing) {
    Navigator.of(context).pushNamed('/listingDetail', arguments: listing);
  }

  void navigateBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void setNavigationReturn(bool hasReturned) {
    _hasReturnedFromNavigation = hasReturned;
    notifyListeners();
  }

  void clearMessages() {
    _successMessage = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> handleAddListingNavigation() async {
    _hasReturnedFromNavigation = true;
    notifyListeners();
  }

  Future<void> handleNavigationResult(String? result) async {
    if (result == 'added' || result == 'updated') {
      debugPrint('🔄 Listing $result successfully, refreshing...');
      await refreshListings();
      _successMessage =
          result == 'added'
              ? 'Listing added successfully'
              : 'Listing updated successfully';
      notifyListeners();
    }
    _hasReturnedFromNavigation = false;
  }

  Future<bool> showDeleteConfirmation({
    required BuildContext context,
    required String listingTitle,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete Listing'),
            content: Text('Are you sure you want to delete "$listingTitle"?'),
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
    return shouldDelete ?? false;
  }

  Future<void> handleDeleteListing({
    required String listingId,
    required String listingTitle,
    required ScaffoldMessengerState scaffoldMessenger,
  }) async {
    try {
      await deleteListing(listingId);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Listing deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _successMessage = 'Listing deleted successfully';
      notifyListeners();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error deleting listing: $e'),
          backgroundColor: Colors.red,
        ),
      );
      _errorMessage = 'Error deleting listing: $e';
      notifyListeners();
    }
  }

  void clearSearchTerm() {
    _searchTerm = '';
    notifyListeners();
  }

  bool get hasListings => _listings.isNotEmpty;

  bool get shouldShowEmptyState {
    return !_isLoading && !_isRefreshing && _errorMessage == null;
  }

  bool get shouldShowLoadingState {
    return _isLoading || _isRefreshing;
  }

  bool get shouldShowErrorState {
    return _errorMessage != null;
  }

  void handleAppLifecycleResume() {
    if (_hasReturnedFromNavigation) {
      debugPrint('🔄 App resumed after navigation, refreshing listings...');
      _hasReturnedFromNavigation = false;
      refreshListings();
    }
  }

  // Debug method to test stream updates
  void forceNotifyListeners() {
    print('🔔 Forcing notifyListeners call');
    notifyListeners();
  }

  // Debug method to check controller state
  void debugControllerState() {
    debugPrint('🔍 Listings count: ${_listings.length}');
    debugPrint(
      '🔍 Subscription state: exists=${_listingsSubscription != null}',
    );
    debugPrint('🔍 Current user: ${_auth.currentUser?.uid}');
    debugPrint('🔍 Current refresh state: $_isRefreshing');
    debugPrint('🔍 Error message: $_errorMessage');
  }
}
