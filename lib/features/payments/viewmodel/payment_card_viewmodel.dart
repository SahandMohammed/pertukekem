import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/interfaces/state_clearable.dart';
import '../model/payment_card_model.dart';
import '../service/payment_card_service.dart';

class PaymentCardViewModel extends ChangeNotifier implements StateClearable {
  final PaymentCardService _cardService = PaymentCardService();

  List<PaymentCard> _cards = [];
  bool _isLoading = false;
  String? _error;
  PaymentCard? _defaultCard;

  List<PaymentCard> get cards => _cards;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PaymentCard? get defaultCard => _defaultCard;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Load all cards for the current user
  Future<void> loadCards() async {
    if (currentUserId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      _cards = await _cardService.getUserPaymentCards(currentUserId!);
      _defaultCard = _cards.where((card) => card.isDefault).firstOrNull;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading cards: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add a new card
  Future<bool> addCard({
    required String cardNumber,
    required String cardHolderName,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    bool setAsDefault = false,
  }) async {
    if (currentUserId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      // Check if card already exists
      final lastFourDigits = cardNumber
          .replaceAll(' ', '')
          .substring(cardNumber.replaceAll(' ', '').length - 4);
      final cardExists = await _cardService.cardExists(
        userId: currentUserId!,
        lastFourDigits: lastFourDigits,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
      );

      if (cardExists) {
        _error = 'This card is already saved';
        _setLoading(false);
        return false;
      }

      await _cardService.savePaymentCard(
        userId: currentUserId!,
        cardNumber: cardNumber,
        cardHolderName: cardHolderName,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvv: cvv,
        setAsDefault: setAsDefault,
      );

      // Reload cards to update the UI
      await loadCards();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding card: $e');
      _setLoading(false);
      return false;
    }
  }

  // Set a card as default
  Future<bool> setCardAsDefault(String cardId) async {
    if (currentUserId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      await _cardService.setCardAsDefault(cardId, currentUserId!);
      await loadCards(); // Reload to update UI
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error setting default card: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete a card
  Future<bool> deleteCard(String cardId) async {
    if (currentUserId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      await _cardService.deletePaymentCard(cardId, currentUserId!);
      await loadCards(); // Reload to update UI
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting card: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get default card
  Future<PaymentCard?> getDefaultCard() async {
    if (currentUserId == null) return null;

    try {
      return await _cardService.getUserDefaultCard(currentUserId!);
    } catch (e) {
      debugPrint('Error getting default card: $e');
      return null;
    }
  }

  // Update card last used
  Future<void> updateCardLastUsed(String cardId) async {
    if (currentUserId == null) return;

    try {
      await _cardService.updateCardLastUsedWithUserId(currentUserId!, cardId);
      // Optionally reload cards if you want to show last used date
    } catch (e) {
      debugPrint('Error updating card last used: $e');
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    Future.microtask(() => notifyListeners());
  }

  // Validate card number format (basic simulation validation)
  static bool isValidCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');
    return cleanNumber.length >= 13 &&
        cleanNumber.length <= 19 &&
        RegExp(r'^\d+$').hasMatch(cleanNumber);
  }

  // Validate expiry date
  static bool isValidExpiryDate(String month, String year) {
    try {
      final monthInt = int.parse(month);
      final yearInt = int.parse('20$year'); // Assuming 2-digit year

      if (monthInt < 1 || monthInt > 12) return false;

      final expiryDate = DateTime(yearInt, monthInt);
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);

      return expiryDate.isAfter(currentMonth) ||
          expiryDate.isAtSameMomentAs(currentMonth);
    } catch (e) {
      return false;
    }
  }

  // Format card number with spaces
  static String formatCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');
    String formatted = '';

    for (int i = 0; i < cleanNumber.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += cleanNumber[i];
    }

    return formatted;
  }

  // Get card type from number
  static String getCardType(String cardNumber) {
    return PaymentCard.determineCardType(cardNumber);
  }

  @override
  Future<void> clearState() async {
    debugPrint('🧹 Clearing PaymentCardViewModel state...');

    // Clear all state
    _cards.clear();
    _defaultCard = null;
    _error = null;
    _isLoading = false;

    // Notify listeners
    notifyListeners();

    debugPrint('✅ PaymentCardViewModel state cleared');
  }
}
