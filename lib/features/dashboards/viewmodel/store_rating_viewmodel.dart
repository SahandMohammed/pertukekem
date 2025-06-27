import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../model/store_rating_model.dart';
import '../service/store_rating_service.dart';

class StoreRatingViewModel extends ChangeNotifier {
  final StoreRatingService _ratingService = StoreRatingService();

  StoreRating? _userRating;
  List<StoreRating> _allRatings = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  Map<String, dynamic>? _ratingStats;
  double _selectedRating = 0.0;
  String _comment = '';

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
      await _loadUserRating(storeId);

      await _loadRatingStats(storeId);

      _listenToStoreRatings(storeId);
    } catch (e) {
      _error = 'Failed to load rating data: $e';
    } finally {
      _isLoading = false;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

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

  Future<void> _loadRatingStats(String storeId) async {
    try {
      _ratingStats = await _ratingService.getStoreRatingStats(storeId);
    } catch (e) {
      _error = 'Failed to load rating stats: $e';
    }
  }

  void _listenToStoreRatings(String storeId) {
    _ratingService
        .getStoreRatings(storeId)
        .listen(
          (ratings) {
            _allRatings = ratings;
            SchedulerBinding.instance.addPostFrameCallback((_) {
              notifyListeners();
            });
          },
          onError: (e) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              _setError('Failed to load ratings: $e');
            });
          },
        );
  }

  void updateRating(double rating) {
    if (_selectedRating == rating) return; // Add this guard
    _selectedRating = rating;
    notifyListeners();
  }

  void updateComment(String comment) {
    if (_comment == comment) return; // Add this guard
    _comment = comment;
    notifyListeners();
  }

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

  Future<bool> deleteRating(String storeId) async {
    _setSubmitting(true);
    _clearError();

    try {
      await _ratingService.deleteRating(storeId);

      _userRating = null;
      _selectedRating = 0.0;
      _comment = '';

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
