import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../cart/model/cart_item_model.dart';
import '../../orders/service/order_service.dart';
import '../../payments/service/transaction_service.dart';
import '../../library/service/library_service.dart';
import '../model/checkout_result_model.dart';

class CheckoutService {
  final OrderService _orderService = OrderService();
  final TransactionService _transactionService = TransactionService();
  final LibraryService _libraryService = LibraryService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Process the entire cart checkout with payment simulation
  Future<List<CheckoutResult>> processCartCheckout({
    required Cart cart,
    required String buyerId,
    required String paymentMethod,
    required String shippingAddress,
    required Map<String, String> customerInfo,
    Map<String, String>? cardInfo,
  }) async {
    final results = <CheckoutResult>[];
    final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';

    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Process payment simulation
      final paymentResult = await _simulatePayment(
        amount: cart.totalAmount,
        paymentMethod: paymentMethod,
        cardInfo: cardInfo,
      );

      if (!paymentResult.success) {
        throw Exception(paymentResult.errorMessage ?? 'Payment failed');
      }

      // Process each cart item as separate order
      for (final cartItem in cart.items) {
        try {
          final orderResult = await _processCartItem(
            cartItem: cartItem,
            buyerId: buyerId,
            transactionId: transactionId,
            paymentMethod: paymentMethod,
            shippingAddress: shippingAddress,
            customerInfo: customerInfo,
            paymentResult: paymentResult,
          );

          results.add(orderResult);
        } catch (e) {
          // Add failed result for this item
          results.add(
            CheckoutResult(
              success: false,
              orderId: '',
              listingId: cartItem.listing.id!,
              listingTitle: cartItem.listing.title,
              sellerId: cartItem.listing.sellerRef.id,
              quantity: cartItem.quantity,
              amount: cartItem.totalPrice,
              errorMessage: e.toString(),
            ),
          );
        }
      }

      return results;
    } catch (e) {
      throw Exception('Checkout failed: ${e.toString()}');
    }
  }

  /// Process individual cart item to create order
  Future<CheckoutResult> _processCartItem({
    required CartItem cartItem,
    required String buyerId,
    required String transactionId,
    required String paymentMethod,
    required String shippingAddress,
    required Map<String, String> customerInfo,
    required PaymentSimulationResult paymentResult,
  }) async {
    try {
      // Create order with correct parameters
      final sellerRef = cartItem.listing.sellerRef;
      final listingRef = _firestore
          .collection('listings')
          .doc(cartItem.listing.id);

      final orderId = await _orderService.createOrder(
        buyerId: buyerId,
        sellerRef: sellerRef,
        listingRef: listingRef,
        totalAmount: cartItem.totalPrice,
        quantity: cartItem.quantity,
        shippingAddress: shippingAddress,
      ); // Create transaction record with correct parameters
      await _transactionService.createTransaction(
        transactionId: transactionId,
        buyerId: buyerId,
        sellerId: cartItem.listing.sellerRef.id,
        listingId: cartItem.listing.id!,
        listingTitle: cartItem.listing.title,
        amount: cartItem.totalPrice,
        paymentMethod: paymentMethod,
        orderId: orderId,
      );

      // Add book to buyer's library if it's a digital item
      if (cartItem.listing.bookType == 'ebook') {
        await _libraryService.addBookToLibrary(
          userId: buyerId,
          listing: cartItem.listing,
          purchaseDate: DateTime.now(),
          orderId: orderId,
          transactionId: transactionId,
        );
      } // Reduce available quantity in listing
      await _reduceListingQuantity(cartItem.listing.id!, cartItem.quantity);
      return CheckoutResult(
        success: true,
        orderId: orderId,
        listingId: cartItem.listing.id!,
        listingTitle: cartItem.listing.title,
        sellerId: cartItem.listing.sellerRef.id,
        quantity: cartItem.quantity,
        amount: cartItem.totalPrice,
        transactionId: transactionId,
      );
    } catch (e) {
      return CheckoutResult(
        success: false,
        orderId: '',
        listingId: cartItem.listing.id!,
        listingTitle: cartItem.listing.title,
        sellerId: cartItem.listing.sellerRef.id,
        quantity: cartItem.quantity,
        amount: cartItem.totalPrice,
        errorMessage: e.toString(),
      );
    }
  }

  /// Simulate payment processing for different payment methods
  Future<PaymentSimulationResult> _simulatePayment({
    required double amount,
    required String paymentMethod,
    Map<String, String>? cardInfo,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    if (paymentMethod == 'cod') {
      // Cash on delivery always succeeds
      return PaymentSimulationResult(
        success: true,
        transactionId: 'COD_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Cash on delivery order confirmed',
      );
    }

    // Card payment simulation
    if (cardInfo == null) {
      return PaymentSimulationResult(
        success: false,
        errorMessage: 'Card information is required',
      );
    }

    // Simulate various payment scenarios
    final random = Random();
    final successRate = 0.9; // 90% success rate for simulation

    if (random.nextDouble() > successRate) {
      // Simulate random failures for demo purposes
      final failureReasons = [
        'Insufficient funds',
        'Card declined',
        'Invalid card number',
        'Card expired',
        'Transaction timeout',
      ];
      return PaymentSimulationResult(
        success: false,
        errorMessage: failureReasons[random.nextInt(failureReasons.length)],
      );
    } // Validate card number format (basic validation)
    // Handle both new card entry and stored card scenarios
    final cardNumber = cardInfo['cardNumber']?.replaceAll(' ', '') ?? '';
    final lastFourDigits = cardInfo['lastFourDigits'] ?? '';

    // For stored cards, we only have last 4 digits, so check that instead
    if (cardNumber.isNotEmpty) {
      // New card validation
      if (cardNumber.length < 16) {
        return PaymentSimulationResult(
          success: false,
          errorMessage: 'Invalid card number',
        );
      }
    } else if (lastFourDigits.isNotEmpty) {
      // Stored card validation - just check if we have the last 4 digits
      if (lastFourDigits.length != 4) {
        return PaymentSimulationResult(
          success: false,
          errorMessage: 'Invalid card information',
        );
      }
    } else {
      // No card information provided
      return PaymentSimulationResult(
        success: false,
        errorMessage: 'Invalid card number',
      );
    }

    // Validate expiry date
    final expiry = cardInfo['expiry'] ?? '';
    if (expiry.length < 5 || !expiry.contains('/')) {
      return PaymentSimulationResult(
        success: false,
        errorMessage: 'Invalid expiry date',
      );
    } // Validate CVV (optional for stored cards in this simulation)
    final cvv = cardInfo['cvv'] ?? '';
    final isStoredCard = cardInfo['cardId']?.isNotEmpty ?? false;

    // For new cards, CVV is required. For stored cards, it's optional in this simulation
    if (!isStoredCard && cvv.length < 3) {
      return PaymentSimulationResult(
        success: false,
        errorMessage: 'Invalid CVV',
      );
    } // Success case
    final last4 =
        cardNumber.isNotEmpty
            ? cardNumber.substring(cardNumber.length - 4)
            : lastFourDigits;

    return PaymentSimulationResult(
      success: true,
      transactionId: 'CARD_${DateTime.now().millisecondsSinceEpoch}',
      message: 'Payment processed successfully',
      last4Digits: last4,
    );
  }

  /// Reduce the available quantity of a listing after successful purchase
  Future<void> _reduceListingQuantity(
    String listingId,
    int quantityPurchased,
  ) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'quantity': FieldValue.increment(-quantityPurchased),
      });
    } catch (e) {
      print('Error reducing listing quantity: $e');
      // Non-critical error, continue with checkout
    }
  }
}

/// Result of payment simulation
class PaymentSimulationResult {
  final bool success;
  final String? transactionId;
  final String? message;
  final String? errorMessage;
  final String? last4Digits;

  PaymentSimulationResult({
    required this.success,
    this.transactionId,
    this.message,
    this.errorMessage,
    this.last4Digits,
  });
}
