import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart' as tx_model;

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'transactions';

  // Create a new transaction
  Future<String> createTransaction({
    required String transactionId,
    required String buyerId,
    required String sellerId,
    required String listingId,
    required String listingTitle,
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
    String? orderId,
  }) async {
    try {
      final transaction = tx_model.Transaction(
        id: '', // Will be set by Firestore
        transactionId: transactionId,
        buyerId: buyerId,
        sellerId: sellerId,
        listingId: listingId,
        listingTitle: listingTitle,
        amount: amount,
        paymentMethod: paymentMethod,
        status: 'pending',
        createdAt: DateTime.now(),
        paymentDetails: paymentDetails,
        orderId: orderId,
      );

      final docRef = await _firestore
          .collection(_collection)
          .add(transaction.toFirestore());

      debugPrint('Transaction created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating transaction: $e');
      rethrow;
    }
  }

  // Update transaction status
  Future<void> updateTransactionStatus({
    required String transactionId,
    required String status,
    DateTime? completedAt,
  }) async {
    try {
      final updateData = <String, dynamic>{'status': status};

      if (completedAt != null) {
        updateData['completedAt'] = Timestamp.fromDate(completedAt);
      }

      await _firestore
          .collection(_collection)
          .doc(transactionId)
          .update(updateData);

      debugPrint('Transaction $transactionId status updated to $status');
    } catch (e) {
      debugPrint('Error updating transaction status: $e');
      rethrow;
    }
  }

  // Get transaction by ID
  Future<tx_model.Transaction?> getTransactionById(String transactionId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(transactionId).get();

      if (doc.exists) {
        return tx_model.Transaction.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting transaction: $e');
      rethrow;
    }
  }

  // Get transaction by transaction ID (the generated TXN string)
  Future<tx_model.Transaction?> getTransactionByTransactionId(
    String transactionId,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('transactionId', isEqualTo: transactionId)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return tx_model.Transaction.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting transaction by transaction ID: $e');
      rethrow;
    }
  }

  // Get all transactions for a user (as buyer)
  Future<List<tx_model.Transaction>> getTransactionsForBuyer(
    String buyerId,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('buyerId', isEqualTo: buyerId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => tx_model.Transaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting transactions for buyer: $e');
      rethrow;
    }
  }

  // Get all transactions for a seller
  Future<List<tx_model.Transaction>> getTransactionsForSeller(
    String sellerId,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('sellerId', isEqualTo: sellerId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => tx_model.Transaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting transactions for seller: $e');
      rethrow;
    }
  }

  // Get all transactions (for admin)
  Future<List<tx_model.Transaction>> getAllTransactions({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => tx_model.Transaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting all transactions: $e');
      rethrow;
    }
  }

  // Get transaction statistics for admin dashboard
  Future<Map<String, dynamic>> getTransactionStatistics() async {
    try {
      final allTransactions = await _firestore.collection(_collection).get();
      final transactions =
          allTransactions.docs
              .map((doc) => tx_model.Transaction.fromFirestore(doc))
              .toList();

      final completed =
          transactions.where((t) => t.status == 'completed').toList();
      final pending = transactions.where((t) => t.status == 'pending').toList();
      final failed = transactions.where((t) => t.status == 'failed').toList();

      final totalRevenue = completed.fold<double>(
        0,
        (sum, t) => sum + t.amount,
      );

      // Get transactions from last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentTransactions =
          transactions
              .where((t) => t.createdAt.isAfter(thirtyDaysAgo))
              .toList();

      return {
        'totalTransactions': transactions.length,
        'completedTransactions': completed.length,
        'pendingTransactions': pending.length,
        'failedTransactions': failed.length,
        'totalRevenue': totalRevenue,
        'recentTransactions': recentTransactions.length,
        'averageTransactionValue':
            completed.isNotEmpty ? totalRevenue / completed.length : 0.0,
      };
    } catch (e) {
      debugPrint('Error getting transaction statistics: $e');
      rethrow;
    }
  }

  // Search transactions
  Future<List<tx_model.Transaction>> searchTransactions({
    String? transactionId,
    String? buyerId,
    String? sellerId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (transactionId != null && transactionId.isNotEmpty) {
        query = query.where('transactionId', isEqualTo: transactionId);
      }

      if (buyerId != null && buyerId.isNotEmpty) {
        query = query.where('buyerId', isEqualTo: buyerId);
      }

      if (sellerId != null && sellerId.isNotEmpty) {
        query = query.where('sellerId', isEqualTo: sellerId);
      }

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      if (startDate != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      query = query.orderBy('createdAt', descending: true);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => tx_model.Transaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error searching transactions: $e');
      rethrow;
    }
  }

  // Complete a transaction
  Future<void> completeTransaction(String transactionId) async {
    await updateTransactionStatus(
      transactionId: transactionId,
      status: 'completed',
      completedAt: DateTime.now(),
    );
  }

  // Fail a transaction
  Future<void> failTransaction(String transactionId) async {
    await updateTransactionStatus(
      transactionId: transactionId,
      status: 'failed',
      completedAt: DateTime.now(),
    );
  }

  // Get transactions by user ID (as buyer or seller)
  Future<List<tx_model.Transaction>> getTransactionsByUserId(
    String userId,
  ) async {
    try {
      // Get transactions where user is buyer
      final buyerQuery = _firestore
          .collection(_collection)
          .where('buyerId', isEqualTo: userId);

      // Get transactions where user is seller
      final sellerQuery = _firestore
          .collection(_collection)
          .where('sellerId', isEqualTo: userId);

      final buyerSnapshot = await buyerQuery.get();
      final sellerSnapshot = await sellerQuery.get();

      final allTransactions = <tx_model.Transaction>[];

      // Add buyer transactions
      allTransactions.addAll(
        buyerSnapshot.docs.map(
          (doc) => tx_model.Transaction.fromFirestore(doc),
        ),
      );

      // Add seller transactions
      allTransactions.addAll(
        sellerSnapshot.docs.map(
          (doc) => tx_model.Transaction.fromFirestore(doc),
        ),
      );

      // Sort by created date, most recent first
      allTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allTransactions;
    } catch (e) {
      debugPrint('Error getting transactions by user ID: $e');
      rethrow;
    }
  }

  // Get transactions by status
  Future<List<tx_model.Transaction>> getTransactionsByStatus(
    String status,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('status', isEqualTo: status)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => tx_model.Transaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting transactions by status: $e');
      rethrow;
    }
  }

  // Get transactions by seller ID - alias for compatibility
  Future<List<tx_model.Transaction>> getTransactionsBySellerId(
    String sellerId,
  ) async {
    return getTransactionsForSeller(sellerId);
  }

  // Refund a transaction
  Future<void> refundTransaction(String transactionId) async {
    await updateTransactionStatus(
      transactionId: transactionId,
      status: 'refunded',
      completedAt: DateTime.now(),
    );
  }
}
