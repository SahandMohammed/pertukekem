class CheckoutResult {
  final bool success;
  final String? orderId;
  final String listingId;
  final String listingTitle;
  final String sellerId;
  final int quantity;
  final double amount;
  final String? transactionId;
  final String? errorMessage;

  CheckoutResult({
    required this.success,
    this.orderId,
    required this.listingId,
    required this.listingTitle,
    required this.sellerId,
    required this.quantity,
    required this.amount,
    this.transactionId,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'orderId': orderId,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'sellerId': sellerId,
      'quantity': quantity,
      'amount': amount,
      'transactionId': transactionId,
      'errorMessage': errorMessage,
    };
  }

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    return CheckoutResult(
      success: json['success'] ?? false,
      orderId: json['orderId'],
      listingId: json['listingId'] ?? '',
      listingTitle: json['listingTitle'] ?? '',
      sellerId: json['sellerId'] ?? '',
      quantity: json['quantity'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      transactionId: json['transactionId'],
      errorMessage: json['errorMessage'],
    );
  }
}
