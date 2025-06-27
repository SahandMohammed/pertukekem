import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../cart/model/cart_item_model.dart';

class CheckoutAppBar extends StatelessWidget {
  final Cart cart;

  const CheckoutAppBar({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onPrimary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.onPrimary.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Checkout',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${cart.totalItems} items • ${NumberFormat.currency(symbol: r'$').format(cart.totalAmount)}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.security_rounded,
              color: colorScheme.onPrimary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
