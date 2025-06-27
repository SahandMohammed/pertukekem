import 'package:flutter/foundation.dart';
import '../../../core/interfaces/state_clearable.dart';
import '../model/book_request_model.dart';
import '../service/book_request_service.dart';
import '../../dashboards/model/store_model.dart';

class BookRequestViewModel extends ChangeNotifier implements StateClearable {
  final BookRequestService _bookRequestService = BookRequestService();

  // State
  List<BookRequest> _customerRequests = [];
  List<BookRequest> _storeRequests = [];
  List<StoreModel> _availableStores = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  int _pendingRequestsCount = 0;

  // Getters
  List<BookRequest> get customerRequests => _customerRequests;
  List<BookRequest> get storeRequests => _storeRequests;
  List<StoreModel> get availableStores => _availableStores;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  int get pendingRequestsCount => _pendingRequestsCount;

  /// Clear all state
  @override
  Future<void> clearState() async {
    _customerRequests.clear();
    _storeRequests.clear();
    _availableStores.clear();
    _isLoading = false;
    _isSubmitting = false;
    _error = null;
    _pendingRequestsCount = 0;
    notifyListeners();
  }

  /// Load customer's book requests
  Future<void> loadCustomerRequests() async {
    _setLoading(true);
    _setError(null);

    try {
      _customerRequests = await _bookRequestService.getCustomerBookRequests();
    } catch (e) {
      _setError('Failed to load your requests: $e');
      debugPrint('Error loading customer requests: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load store's book requests
  Future<void> loadStoreRequests() async {
    _setLoading(true);
    _setError(null);

    try {
      _storeRequests = await _bookRequestService.getStoreBookRequests();
      _pendingRequestsCount = _storeRequests
          .where((request) => request.status == BookRequestStatus.pending)
          .length;
    } catch (e) {
      _setError('Failed to load store requests: $e');
      debugPrint('Error loading store requests: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load available stores
  Future<void> loadAvailableStores() async {
    _setLoading(true);
    _setError(null);

    try {
      _availableStores = await _bookRequestService.getAvailableStores();
    } catch (e) {
      _setError('Failed to load stores: $e');
      debugPrint('Error loading available stores: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Submit a book request
  Future<bool> submitBookRequest({
    required String storeId,
    required String storeName,
    required String bookTitle,
    String? note,
  }) async {
    _setSubmitting(true);
    _setError(null);

    try {
      await _bookRequestService.submitBookRequest(
        storeId: storeId,
        storeName: storeName,
        bookTitle: bookTitle,
        note: note,
      );

      // Refresh customer requests
      await loadCustomerRequests();
      return true;
    } catch (e) {
      _setError('Failed to submit request: $e');
      debugPrint('Error submitting book request: $e');
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  /// Respond to a book request (store owner)
  Future<bool> respondToRequest({
    required String requestId,
    required BookRequestStatus status,
    String? response,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _bookRequestService.respondToBookRequest(
        requestId: requestId,
        status: status,
        response: response,
      );

      // Refresh store requests
      await loadStoreRequests();
      return true;
    } catch (e) {
      _setError('Failed to respond to request: $e');
      debugPrint('Error responding to book request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel a book request (customer)
  Future<bool> cancelRequest(String requestId) async {
    _setLoading(true);
    _setError(null);

    try {
      await _bookRequestService.cancelBookRequest(requestId);

      // Refresh customer requests
      await loadCustomerRequests();
      return true;
    } catch (e) {
      _setError('Failed to cancel request: $e');
      debugPrint('Error cancelling book request: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get pending requests count for store
  Future<void> loadPendingRequestsCount() async {
    try {
      _pendingRequestsCount =
          await _bookRequestService.getPendingRequestsCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading pending requests count: $e');
    }
  }

  /// Filter requests by status
  List<BookRequest> getRequestsByStatus(
    List<BookRequest> requests,
    BookRequestStatus? status,
  ) {
    if (status == null) return requests;
    return requests.where((request) => request.status == status).toList();
  }

  /// Get requests grouped by status
  Map<BookRequestStatus, List<BookRequest>> getRequestsGroupedByStatus(
    List<BookRequest> requests,
  ) {
    final grouped = <BookRequestStatus, List<BookRequest>>{};

    for (final status in BookRequestStatus.values) {
      grouped[status] = requests
          .where((request) => request.status == status)
          .toList();
    }

    return grouped;
  }

  /// Clear error
  void clearError() {
    _setError(null);
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSubmitting(bool submitting) {
    _isSubmitting = submitting;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
