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

  StreamController<List<Listing>>? _controller;
  StreamSubscription<List<Listing>>? _subscription;

  Stream<List<Listing>>? get sellerListingsStream {
    debugPrint(
      '🔍 Getting sellerListingsStream - controller exists: ${_controller != null}, closed: ${_controller?.isClosed}',
    );
    return _searchTerm.isEmpty
        ? _controller?.stream
        : _controller?.stream.map((listings) => _filterListings(listings));
  }

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

  ManageListingsViewModel() {
    _controller = StreamController<List<Listing>>.broadcast();
    _initSellerListingsStream();
  }
  @override
  void dispose() {
    _subscription?.cancel();
    _controller?.close();
    super.dispose();
  }

  @override
  Future<void> clearState() async {
    debugPrint('🧹 Clearing ManageListingsViewModel state...');

    // Cancel subscription and close stream controller
    _subscription?.cancel();
    _subscription = null;

    await _controller?.close();
    _controller = null;

    // Clear all state
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

  void _initSellerListingsStream() {
    final currentUser = _auth.currentUser;
    print('Loading seller listings for user: ${currentUser?.uid}');

    if (currentUser != null) {
      String sellerId = currentUser.uid;

      // Ensure we have a valid controller
      if (_controller == null || _controller!.isClosed) {
        _controller = StreamController<List<Listing>>.broadcast();
      }

      // First check if user is a store owner
      _firestore
          .collection('stores')
          .doc(sellerId)
          .get()
          .then((storeDoc) async {
            print('Store doc exists: ${storeDoc.exists}');
            print('Store id: ${storeDoc.id}');

            // Use the appropriate collection based on seller type
            String sellerType = storeDoc.exists ? "store" : "user";
            DocumentReference sellerRef = _firestore
                .collection(sellerType == 'store' ? 'stores' : 'users')
                .doc(sellerId);

            print('Setting up listings stream with:');
            print('- sellerType: $sellerType');
            print('- sellerRef: ${sellerRef.path}');

            // Cancel any existing subscription
            _subscription?.cancel();

            // Set up the stream with both filters
            final firestoreStream = _listingService.watchAllListings(
              sellerRef: sellerRef,
              sellerType: sellerType,
            ); // Subscribe to the Firestore stream and forward data to our controller
            _subscription = firestoreStream.listen(
              (listings) {
                print('📦 Received ${listings.length} listings from Firestore');
                listings.forEach((listing) {
                  print(
                    '- ${listing.id}: ${listing.title}, type: ${listing.sellerType}, ref: ${listing.sellerRef.path}',
                  );
                });

                // Add data to our controller if it's still valid
                if (_controller != null && !_controller!.isClosed) {
                  print('✅ Adding listings to stream controller');
                  _controller!.add(listings);
                } else {
                  print('❌ Controller is null or closed, cannot add listings');
                }

                // Clear refreshing state when we get new data
                if (_isRefreshing) {
                  print('🔄 Clearing refresh state');
                  _isRefreshing = false;
                  notifyListeners();
                }
              },
              onError: (error) {
                print('Error in listings stream: $error');
                _errorMessage = error.toString();
                _isRefreshing = false;
                notifyListeners();

                // Add error to controller if it's still valid
                if (_controller != null && !_controller!.isClosed) {
                  _controller!.addError(error);
                }
              },
            );

            notifyListeners();
          })
          .catchError((error) {
            print('Error checking store doc: $error');
            _errorMessage = "Error determining seller type: $error";
            _isRefreshing = false;
            notifyListeners();

            // Add empty list on error if controller is still valid
            if (_controller != null && !_controller!.isClosed) {
              _controller!.add([]);
            }
          });
    } else {
      print('No authenticated user');
      _errorMessage = "User not authenticated.";
      _isRefreshing = false;
      notifyListeners();

      // Add empty list when no user if controller is still valid
      if (_controller != null && !_controller!.isClosed) {
        _controller!.add([]);
      }
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
      // Cancel existing subscription and recreate stream controller
      _subscription?.cancel();
      _subscription = null;

      // Close and recreate the stream controller
      if (_controller != null && !_controller!.isClosed) {
        await _controller!.close();
      }
      _controller = StreamController<List<Listing>>.broadcast();

      // Reinitialize the stream to get fresh data
      _initSellerListingsStream();

      print('✅ Listings refresh initiated');
    } catch (e) {
      print('❌ Error refreshing listings: $e');
      _errorMessage = e.toString();
      _isRefreshing = false;
      notifyListeners();
    }
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

  bool get hasListings => _controller?.stream != null;

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
    debugPrint(
      '🔍 Controller state: exists=${_controller != null}, closed=${_controller?.isClosed}',
    );
    debugPrint('🔍 Subscription state: exists=${_subscription != null}');
    debugPrint('🔍 Current refresh state: $_isRefreshing');
  }
}
