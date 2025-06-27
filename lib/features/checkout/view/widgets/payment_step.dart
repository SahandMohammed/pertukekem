import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/checkout_viewmodel.dart';
import 'empty_cards_card.dart';
import 'loading_card.dart';
import 'payment_method_selection.dart';
import 'payment_card_selection.dart';
import 'payment_security_info.dart';

class PaymentStep extends StatelessWidget {
  const PaymentStep({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<CheckoutViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you\'d like to pay',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              const PaymentMethodSelection(),
              if (viewModel.selectedPaymentMethod == 'card') ...[
                const SizedBox(height: 24),
                if (viewModel.isLoadingCards)
                  const LoadingCard(message: 'Loading payment cards...')
                else if (viewModel.userCards.isEmpty)
                  const EmptyCardsCard()
                else
                  const PaymentCardSelection(),
              ],
              const SizedBox(height: 32),
              const PaymentSecurityInfo(),
              const SizedBox(height: 100), // Space for bottom bar
            ],
          ),
        );
      },
    );
  }
}
