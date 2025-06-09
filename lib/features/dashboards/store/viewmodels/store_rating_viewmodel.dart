import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/store_rating_model.dart';
import '../services/store_rating_service.dart';

class StoreRatingViewModel extends ChangeNotifier {
  final StoreRatingService _ratingService = StoreRatingService();

  // Current state
  StoreRating? _userRating;
  List<StoreRating> _allRatings = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  Map<String, dynamic>? _ratingStats;
  // Form state
  double _selectedRating = 0.0;
  String _comment = '';

  // Getters
  StoreRating? get userRating => _userRating;
  List<StoreRating> get allRatings => _allRatings;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  Map<String, dynamic>? get ratingStats => _ratingStats;
  double get selectedRating => _selectedRating;
  String get comment => _comment;
  bool get hasUserRated => _userRating != null;

  double get averageRating => _ratingStats?['avgRating']?.toDouble() ?? 0.0;
  int get totalRatings => _ratingStats?['totalRatings']?.toInt() ?? 0;
  Map<int, int> get ratingDistribution =>
      _ratingStats?['ratingDistribution']?.cast<int, int>() ??
      {5: 0, 4: 0, 3: 0, 2: 0, 1: 0}; // Initialize data for a store
  Future<void> initialize(String storeId) async {
    _isLoading = true;
    _error = null;

    try {
      // Load user's rating
      await _loadUserRating(storeId);

      // Load rating stats
      await _loadRatingStats(storeId);

      // Listen to all ratings
      _listenToStoreRatings(storeId);
    } catch (e) {
      _error = 'Failed to load rating data: $e';
    } finally {
      _isLoading = false;

      // Use post frame callback to notify listeners after build is complete
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Load user's current rating
  Future<void> _loadUserRating(String storeId) async {
    try {
      _userRating = await _ratingService.getUserRating(storeId);
      if (_userRating != null) {
        _selectedRating = _userRating!.rating;
        _comment = _userRating!.comment;
      }
    } catch (e) {
      _error = 'Failed to load user rating: $e';
    }
  }

  // Load rating statistics
  Future<void> _loadRatingStats(String storeId) async {
    try {
      _ratingStats = await _ratingService.getStoreRatingStats(storeId);
    } catch (e) {
      _error = 'Failed to load rating stats: $e';
    }
  }

  // Listen to store ratings in real-time
  void _listenToStoreRatings(String storeId) {
    _ratingService
        .getStoreRatings(storeId)
        .listen(
          (ratings) {
            _allRatings = ratings;
            // Use post frame callback to avoid setState during build
            SchedulerBinding.instance.addPostFrameCallback((_) {
              notifyListeners();
            });
          },
          onError: (e) {
            // Use post frame callback for error handling too
            SchedulerBinding.instance.addPostFrameCallback((_) {
              _setError('Failed to load ratings: $e');
            });
          },
        );
  }

  // Update selected rating
  void updateRating(double rating) {
    if (_selectedRating == rating) return; // Add this guard
    _selectedRating = rating;
    notifyListeners();
  }

  // Update comment
  void updateComment(String comment) {
    if (_comment == comment) return; // Add this guard
    _comment = comment;
    notifyListeners();
  }

  // Submit or update rating
  Future<bool> submitRating(String storeId) async {
    if (_selectedRating == 0.0) {
      _setError('Please select a rating');
      return false;
    }

    _setSubmitting(true);
    _clearError();

    try {
      await _ratingService.submitRating(
        storeId: storeId,
        rating: _selectedRating,
        comment: _comment.trim(),
      );

      // Reload user rating and stats
      await _loadUserRating(storeId);
      await _loadRatingStats(storeId);

      _setSubmitting(false);
      return true;
    } catch (e) {
      _setError('Failed to submit rating: $e');
      _setSubmitting(false);
      return false;
    }
  }

  // Delete user's rating
  Future<bool> deleteRating(String storeId) async {
    _setSubmitting(true);
    _clearError();

    try {
      await _ratingService.deleteRating(storeId);

      // Reset state
      _userRating = null;
      _selectedRating = 0.0;
      _comment = '';

      // Reload stats
      await _loadRatingStats(storeId);

      _setSubmitting(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete rating: $e');
      _setSubmitting(false);
      return false;
    }
  }

  // Reset form
  void resetForm() {
    if (_userRating != null) {
      _selectedRating = _userRating!.rating;
      _comment = _userRating!.comment;
    } else {
      _selectedRating = 0.0;
      _comment = '';
    }
    _clearError();
    notifyListeners();
  }

  // Validation
  bool get isFormValid => _selectedRating > 0.0;

  String? validateRating() {
    if (_selectedRating == 0.0) {
      return 'Please select a rating';
    }
    return null;
  } // Helper methods

  void _setSubmitting(bool submitting) {
    _isSubmitting = submitting;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
