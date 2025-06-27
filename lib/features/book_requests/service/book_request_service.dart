import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/book_request_model.dart';
import '../../dashboards/model/store_model.dart';

class BookRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'book_requests';

  /// Submit a book request from customer to store
  Future<String> submitBookRequest({
    required String storeId,
    required String storeName,
    required String bookTitle,
    String? note,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get customer information
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userData = userDoc.data()!;
      final customerName =
          '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();

      if (customerName.isEmpty) {
        throw Exception('Customer name not found in profile');
      }

      // Create book request
      final bookRequest = BookRequest(
        id: '', // Will be set by Firestore
        customerId: currentUser.uid,
        customerName: customerName,
        storeId: storeId,
        storeName: storeName,
        bookTitle: bookTitle.trim(),
        note: note?.trim(),
        status: BookRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      // Add to Firestore
      final docRef = await _firestore
          .collection(_collection)
          .add(bookRequest.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit book request: $e');
    }
  }

  /// Get book requests for a customer
  Future<List<BookRequest>> getCustomerBookRequests() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('customerId', isEqualTo: currentUser.uid)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => BookRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get customer book requests: $e');
    }
  }

  /// Get book requests for a store
  Future<List<BookRequest>> getStoreBookRequests() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get user's store ID
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final storeId = userDoc.data()?['storeId'];
      if (storeId == null) {
        throw Exception('User does not have a store');
      }

      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('storeId', isEqualTo: storeId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => BookRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get store book requests: $e');
    }
  }

  /// Stream book requests for a customer (real-time updates)
  Stream<List<BookRequest>> streamCustomerBookRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.empty();
    }

    return _firestore
        .collection(_collection)
        .where('customerId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => BookRequest.fromFirestore(doc))
                  .toList(),
        );
  }

  /// Stream book requests for a store (real-time updates)
  Stream<List<BookRequest>> streamStoreBookRequests() async* {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      yield [];
      return;
    }

    try {
      // Get user's store ID
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        yield [];
        return;
      }

      final storeId = userDoc.data()?['storeId'];
      if (storeId == null) {
        yield [];
        return;
      }

      yield* _firestore
          .collection(_collection)
          .where('storeId', isEqualTo: storeId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => BookRequest.fromFirestore(doc))
                    .toList(),
          );
    } catch (e) {
      yield [];
    }
  }

  /// Respond to a book request (store owner)
  Future<void> respondToBookRequest({
    required String requestId,
    required BookRequestStatus status,
    String? response,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'status': status.name,
        'storeResponse': response,
        'responseDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to respond to book request: $e');
    }
  }

  /// Cancel a book request (customer)
  Future<void> cancelBookRequest(String requestId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Verify the request belongs to the current user
      final requestDoc =
          await _firestore.collection(_collection).doc(requestId).get();

      if (!requestDoc.exists) {
        throw Exception('Request not found');
      }

      final requestData = requestDoc.data()!;
      if (requestData['customerId'] != currentUser.uid) {
        throw Exception('Unauthorized to cancel this request');
      }

      if (requestData['status'] != BookRequestStatus.pending.name) {
        throw Exception('Can only cancel pending requests');
      }

      await _firestore.collection(_collection).doc(requestId).update({
        'status': BookRequestStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel book request: $e');
    }
  }

  /// Get all available stores for book requests
  Future<List<StoreModel>> getAvailableStores() async {
    try {
      final querySnapshot =
          await _firestore.collection('stores').orderBy('storeName').get();

      return querySnapshot.docs
          .map((doc) => StoreModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get available stores: $e');
    }
  }

  /// Get pending requests count for store
  Future<int> getPendingRequestsCount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) return 0;

      final storeId = userDoc.data()?['storeId'];
      if (storeId == null) return 0;

      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('storeId', isEqualTo: storeId)
              .where('status', isEqualTo: BookRequestStatus.pending.name)
              .count()
              .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Delete a book request (admin only or completed requests)
  Future<void> deleteBookRequest(String requestId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore.collection(_collection).doc(requestId).delete();
    } catch (e) {
      throw Exception('Failed to delete book request: $e');
    }
  }
}
