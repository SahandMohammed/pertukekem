import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentCard {
  final String id;
  final String userId;
  final String cardHolderName;
  final String lastFourDigits;
  final String cardType; // 'visa', 'mastercard', 'amex', etc.
  final String expiryMonth;
  final String expiryYear;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  // Note: We never store the full card number or CVV for security

  PaymentCard({
    required this.id,
    required this.userId,
    required this.cardHolderName,
    required this.lastFourDigits,
    required this.cardType,
    required this.expiryMonth,
    required this.expiryYear,
    required this.isDefault,
    required this.createdAt,
    this.lastUsedAt,
  });

  // Factory constructor to create PaymentCard from Firestore document
  factory PaymentCard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentCard(
      id: doc.id,
      userId: data['userId'] ?? '',
      cardHolderName: data['cardHolderName'] ?? '',
      lastFourDigits: data['lastFourDigits'] ?? '',
      cardType: data['cardType'] ?? '',
      expiryMonth: data['expiryMonth'] ?? '',
      expiryYear: data['expiryYear'] ?? '',
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUsedAt:
          data['lastUsedAt'] != null
              ? (data['lastUsedAt'] as Timestamp).toDate()
              : null,
    );
  }

  // Convert PaymentCard to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'cardHolderName': cardHolderName,
      'lastFourDigits': lastFourDigits,
      'cardType': cardType,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUsedAt': lastUsedAt != null ? Timestamp.fromDate(lastUsedAt!) : null,
    };
  }

  // Get masked card number for display
  String get maskedCardNumber {
    return '**** **** **** $lastFourDigits';
  }

  // Get formatted expiry date
  String get formattedExpiry {
    return '$expiryMonth/$expiryYear';
  }

  // Check if card is expired
  bool get isExpired {
    final now = DateTime.now();
    final expiryDate = DateTime(
      int.parse('20$expiryYear'),
      int.parse(expiryMonth),
    );
    return now.isAfter(expiryDate);
  }

  // Check if card is expiring soon (within 30 days)
  bool get isExpiringSoon {
    final now = DateTime.now();
    final expiryDate = DateTime(
      int.parse('20$expiryYear'),
      int.parse(expiryMonth),
    );
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    return expiryDate.isBefore(thirtyDaysFromNow) && !isExpired;
  }

  // Copy with method for updating card
  PaymentCard copyWith({
    String? id,
    String? userId,
    String? cardHolderName,
    String? lastFourDigits,
    String? cardType,
    String? expiryMonth,
    String? expiryYear,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return PaymentCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      cardType: cardType ?? this.cardType,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  // Determine card type from card number
  static String determineCardType(String cardNumber) {
    cardNumber = cardNumber.replaceAll(' ', '');

    if (cardNumber.startsWith('4')) {
      return 'visa';
    } else if (cardNumber.startsWith(RegExp(r'5[1-5]')) ||
        cardNumber.startsWith(RegExp(r'2[2-7]'))) {
      return 'mastercard';
    } else if (cardNumber.startsWith(RegExp(r'3[47]'))) {
      return 'amex';
    } else if (cardNumber.startsWith('6011') ||
        cardNumber.startsWith('65') ||
        cardNumber.startsWith(RegExp(r'64[4-9]'))) {
      return 'discover';
    } else {
      return 'unknown';
    }
  }

  @override
  String toString() {
    return 'PaymentCard{id: $id, lastFourDigits: $lastFourDigits, cardType: $cardType}';
  }
}
