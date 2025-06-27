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

    await Future.delayed(const Duration(seconds: 2));

    try {
      final paymentResult = await _simulatePayment(
        amount: cart.totalAmount,
        paymentMethod: paymentMethod,
        cardInfo: cardInfo,
      );

      if (!paymentResult.success) {
        throw Exception(paymentResult.errorMessage ?? 'Payment failed');
      }

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
      String? orderId;

      if (cartItem.listing.bookType == 'physical') {
        final sellerRef = cartItem.listing.sellerRef;
        final listingRef = _firestore
            .collection('listings')
            .doc(cartItem.listing.id);

        orderId = await _orderService.createOrder(
          buyerId: buyerId,
          sellerRef: sellerRef,
          listingRef: listingRef,
          totalAmount: cartItem.totalPrice,
          quantity: cartItem.quantity,
          shippingAddress: shippingAddress,
        );
      }

      await _transactionService.createTransaction(
        transactionId: transactionId,
        buyerId: buyerId,
        sellerId: cartItem.listing.sellerRef.id,
        listingId: cartItem.listing.id!,
        listingTitle: cartItem.listing.title,
        amount: cartItem.totalPrice,
        paymentMethod: paymentMethod,
        orderId: orderId, // Will be null for ebooks
      );

      if (cartItem.listing.bookType == 'ebook') {
        await _libraryService.addBookToLibrary(
          userId: buyerId,
          listing: cartItem.listing,
          purchaseDate: DateTime.now(),
          orderId: orderId, // Will be null for ebooks
          transactionId: transactionId,
        );
      }

      await _reduceListingQuantity(cartItem.listing.id!, cartItem.quantity);

      return CheckoutResult(
        success: true,
        orderId: orderId ?? '', // Use empty string for ebooks
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

  Future<PaymentSimulationResult> _simulatePayment({
    required double amount,
    required String paymentMethod,
    Map<String, String>? cardInfo,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (paymentMethod == 'cod') {
      return PaymentSimulationResult(
        success: true,
        transactionId: 'COD_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Cash on delivery order confirmed',
      );
    }

    if (cardInfo == null) {
      return PaymentSimulationResult(
        success: false,
        errorMessage: 'Card information is required',
      );
    }

    final random = Random();
    final successRate = 0.9; // 90% success rate for simulation

    if (random.nextDouble() > successRate) {
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
    final cardNumber = cardInfo['cardNumber']?.replaceAll(' ', '') ?? '';
    final lastFourDigits = cardInfo['lastFourDigits'] ?? '';

    if (cardNumber.isNotEmpty) {
      if (cardNumber.length < 16) {
        return PaymentSimulationResult(
          success: false,
          errorMessage: 'Invalid card number',
        );
      }
    } else if (lastFourDigits.isNotEmpty) {
      if (lastFourDigits.length != 4) {
        return PaymentSimulationResult(
          success: false,
          errorMessage: 'Invalid card information',
        );
      }
    } else {
      return PaymentSimulationResult(
        success: false,
        errorMessage: 'Invalid card number',
      );
    }

    final expiry = cardInfo['expiry'] ?? '';
    if (expiry.length < 5 || !expiry.contains('/')) {
      return PaymentSimulationResult(
        success: false,
        errorMessage: 'Invalid expiry date',
      );
    } // Validate CVV (optional for stored cards in this simulation)
    final cvv = cardInfo['cvv'] ?? '';
    final isStoredCard = cardInfo['cardId']?.isNotEmpty ?? false;

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
    }
  }
}

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
