import 'package:flutter/material.dart';
import 'package:pertukekem/core/services/listing_service.dart';
import 'package:pertukekem/features/listings/model/listing_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ManageListingsViewModel extends ChangeNotifier {
  final ListingService _listingService = ListingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamController<List<Listing>>? _controller;
  StreamSubscription<List<Listing>>? _subscription;

  Stream<List<Listing>>? get sellerListingsStream =>
      _searchTerm.isEmpty
          ? _controller?.stream
          : _controller?.stream.map((listings) => _filterListings(listings));

  String _searchTerm = '';
  String get searchTerm => _searchTerm;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

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

  void _initSellerListingsStream() {
    final currentUser = _auth.currentUser;
    print('Loading seller listings for user: ${currentUser?.uid}');
    if (currentUser != null) {
      String sellerId = currentUser.uid;

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
            );

            // Subscribe to the Firestore stream and forward data to our controller
            _subscription = firestoreStream.listen(
              (listings) {
                print('Received ${listings.length} listings');
                listings.forEach((listing) {
                  print(
                    '- ${listing.id}: ${listing.title}, type: ${listing.sellerType}, ref: ${listing.sellerRef.path}',
                  );
                });

                // Add data to our controller
                if (!_controller!.isClosed) {
                  _controller!.add(listings);
                }

                // Clear refreshing state when we get new data
                if (_isRefreshing) {
                  _isRefreshing = false;
                  notifyListeners();
                }
              },
              onError: (error) {
                print('Error in listings stream: $error');
                _errorMessage = error.toString();
                _isRefreshing = false;
                notifyListeners();

                // Add error to controller
                if (!_controller!.isClosed) {
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

            // Add empty list on error
            if (!_controller!.isClosed) {
              _controller!.add([]);
            }
          });
    } else {
      print('No authenticated user');
      _errorMessage = "User not authenticated.";
      _isRefreshing = false;
      notifyListeners();

      // Add empty list when no user
      if (!_controller!.isClosed) {
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
      // Mark as refreshing to show loading state
      _isRefreshing = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateListing(Listing listing) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _listingService.updateListing(listing);
      // Mark as refreshing to show loading state
      _isRefreshing = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteListing(String listingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _listingService.deleteListing(listingId);
      // Mark as refreshing to show loading state
      _isRefreshing = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  } // Call this if you need to refresh the listings manually

  Future<void> refreshListings() async {
    _isRefreshing = true;
    notifyListeners();

    // Reinitialize the stream to get fresh data
    _initSellerListingsStream();
  }
}
