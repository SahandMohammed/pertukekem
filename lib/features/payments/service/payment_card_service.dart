import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/payment_card_model.dart';

class PaymentCardService {
  static final PaymentCardService _instance = PaymentCardService._internal();
  factory PaymentCardService() => _instance;
  PaymentCardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';
  final String _cardsSubcollection = 'payment_cards';

  // Get user's cards collection reference
  CollectionReference _getUserCardsCollection(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_cardsSubcollection);
  }

  // Get user document reference
  DocumentReference _getUserDocumentReference(String userId) {
    return _firestore.collection(_usersCollection).doc(userId);
  }

  // Save a new payment card
  Future<String> savePaymentCard({
    required String userId,
    required String cardNumber,
    required String cardHolderName,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    bool setAsDefault = false,
  }) async {
    try {
      // Ensure user document exists
      await _ensureUserDocumentExists(userId);

      // Extract last 4 digits and determine card type
      final lastFourDigits = cardNumber
          .replaceAll(' ', '')
          .substring(cardNumber.replaceAll(' ', '').length - 4);
      final cardType = PaymentCard.determineCardType(cardNumber);

      // If this is set as default, unset other default cards
      if (setAsDefault) {
        await _unsetDefaultCards(userId);
      } else {
        // If this is the first card, make it default
        final existingCards = await getUserPaymentCards(userId);
        setAsDefault = existingCards.isEmpty;
      }

      final paymentCard = PaymentCard(
        id: '', // Will be set by Firestore
        userId: userId,
        cardHolderName: cardHolderName,
        lastFourDigits: lastFourDigits,
        cardType: cardType,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        isDefault: setAsDefault,
        createdAt: DateTime.now(),
      );

      final docRef = await _getUserCardsCollection(
        userId,
      ).add(paymentCard.toFirestore());

      debugPrint('Payment card saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error saving payment card: $e');
      rethrow;
    }
  }

  // Get all payment cards for a user
  Future<List<PaymentCard>> getUserPaymentCards(String userId) async {
    try {
      final querySnapshot =
          await _getUserCardsCollection(userId)
              .orderBy('isDefault', descending: true)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => PaymentCard.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user payment cards: $e');
      rethrow;
    }
  }

  // Get user's default payment card
  Future<PaymentCard?> getUserDefaultCard(String userId) async {
    try {
      final querySnapshot =
          await _getUserCardsCollection(
            userId,
          ).where('isDefault', isEqualTo: true).limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        return PaymentCard.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting default payment card: $e');
      rethrow;
    }
  }

  // Get payment card by ID
  Future<PaymentCard?> getPaymentCardById(String userId, String cardId) async {
    try {
      final doc = await _getUserCardsCollection(userId).doc(cardId).get();

      if (doc.exists) {
        return PaymentCard.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting payment card: $e');
      rethrow;
    }
  }

  // Set a card as default
  Future<void> setCardAsDefault(String cardId, String userId) async {
    try {
      // First unset all other default cards for this user
      await _unsetDefaultCards(userId);

      // Then set this card as default
      await _getUserCardsCollection(
        userId,
      ).doc(cardId).update({'isDefault': true});

      debugPrint('Card $cardId set as default');
    } catch (e) {
      debugPrint('Error setting card as default: $e');
      rethrow;
    }
  }

  // Update last used date for a card
  Future<void> updateCardLastUsed(String cardId) async {
    // This method needs userId parameter in the new structure
    throw Exception(
      'updateCardLastUsed requires userId parameter. Use updateCardLastUsedWithUserId instead.',
    );
  }

  // Update last used date for a card with userId
  Future<void> updateCardLastUsedWithUserId(
    String userId,
    String cardId,
  ) async {
    try {
      await _getUserCardsCollection(
        userId,
      ).doc(cardId).update({'lastUsedAt': Timestamp.fromDate(DateTime.now())});

      debugPrint('Card $cardId last used date updated');
    } catch (e) {
      debugPrint('Error updating card last used: $e');
      rethrow;
    }
  }

  // Delete a payment card
  Future<void> deletePaymentCard(String cardId, String userId) async {
    try {
      final card = await getPaymentCardById(userId, cardId);
      if (card == null) {
        throw Exception('Card not found');
      }

      // If this was the default card, set another card as default
      if (card.isDefault) {
        final otherCards = await getUserPaymentCards(userId);
        final remainingCards = otherCards.where((c) => c.id != cardId).toList();

        if (remainingCards.isNotEmpty) {
          await setCardAsDefault(remainingCards.first.id, userId);
        }
      }

      await _getUserCardsCollection(userId).doc(cardId).delete();

      debugPrint('Payment card $cardId deleted');
    } catch (e) {
      debugPrint('Error deleting payment card: $e');
      rethrow;
    }
  }

  // Alias method for compatibility
  Future<List<PaymentCard>> getCardsByUserId(String userId) async {
    return getUserPaymentCards(userId);
  }

  // Set default card - alias for compatibility
  Future<void> setDefaultCard(String userId, String cardId) async {
    return setCardAsDefault(cardId, userId);
  }

  // Delete card - alias for compatibility - deprecated
  Future<void> deleteCard(String cardId) async {
    throw Exception(
      'deleteCard requires userId parameter. Use deletePaymentCard instead.',
    );
  }

  // Private method to unset all default cards for a user
  Future<void> _unsetDefaultCards(String userId) async {
    try {
      final querySnapshot =
          await _getUserCardsCollection(
            userId,
          ).where('isDefault', isEqualTo: true).get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error unsetting default cards: $e');
      rethrow;
    }
  }

  // Check if a card already exists (by last 4 digits and expiry)
  Future<bool> cardExists({
    required String userId,
    required String lastFourDigits,
    required String expiryMonth,
    required String expiryYear,
  }) async {
    try {
      final querySnapshot =
          await _getUserCardsCollection(userId)
              .where('lastFourDigits', isEqualTo: lastFourDigits)
              .where('expiryMonth', isEqualTo: expiryMonth)
              .where('expiryYear', isEqualTo: expiryYear)
              .limit(1)
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if card exists: $e');
      rethrow;
    }
  }

  // Get card statistics for admin (requires collection group query)
  Future<Map<String, dynamic>> getCardStatistics() async {
    try {
      // Use collection group query to get all cards across all users
      final allCardsQuery =
          await _firestore.collectionGroup(_cardsSubcollection).get();

      final cards =
          allCardsQuery.docs
              .map((doc) => PaymentCard.fromFirestore(doc))
              .toList();

      // Group by card type
      final cardTypeCount = <String, int>{};
      for (final card in cards) {
        cardTypeCount[card.cardType] = (cardTypeCount[card.cardType] ?? 0) + 1;
      }

      // Count expired cards
      final expiredCards = cards.where((card) => card.isExpired).length;

      // Get cards added in last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentCards =
          cards.where((card) => card.createdAt.isAfter(thirtyDaysAgo)).length;

      return {
        'totalCards': cards.length,
        'cardTypeBreakdown': cardTypeCount,
        'expiredCards': expiredCards,
        'recentCards': recentCards,
        'uniqueUsers': cards.map((card) => card.userId).toSet().length,
      };
    } catch (e) {
      debugPrint('Error getting card statistics: $e');
      rethrow;
    }
  }

  // Remove expired cards for a user
  Future<void> removeExpiredCards(String userId) async {
    try {
      final userCards = await getUserPaymentCards(userId);
      final expiredCards = userCards.where((card) => card.isExpired).toList();

      final batch = _firestore.batch();
      for (final card in expiredCards) {
        final docRef = _getUserCardsCollection(userId).doc(card.id);
        batch.delete(docRef);
      }

      await batch.commit();
      debugPrint(
        'Removed ${expiredCards.length} expired cards for user $userId',
      );
    } catch (e) {
      debugPrint('Error removing expired cards: $e');
      rethrow;
    }
  }

  // Ensure user document exists
  Future<void> _ensureUserDocumentExists(String userId) async {
    try {
      final userDoc = await _getUserDocumentReference(userId).get();
      if (!userDoc.exists) {
        // Create user document with minimal data
        await _getUserDocumentReference(userId).set({
          'id': userId,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'hasPaymentCards': true,
        }, SetOptions(merge: true));
        debugPrint('Created user document for $userId');
      }
    } catch (e) {
      debugPrint('Error ensuring user document exists: $e');
      rethrow;
    }
  }
}
