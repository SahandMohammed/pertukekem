import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../payments/model/payment_card_model.dart';
import '../../viewmodel/checkout_viewmodel.dart';

class PaymentCardSelection extends StatelessWidget {
  const PaymentCardSelection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<CheckoutViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.credit_card_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Select Payment Card',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Navigate to manage cards
                      },
                      icon: const Icon(Icons.settings_rounded, size: 16),
                      label: const Text('Manage'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...viewModel.userCards.map(
                (card) => _PaymentCardOption(card: card),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentCardOption extends StatelessWidget {
  final PaymentCard card;

  const _PaymentCardOption({required this.card});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<CheckoutViewModel>(
      builder: (context, viewModel, child) {
        final isSelected = viewModel.selectedCard?.id == card.id;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                viewModel.selectCard(card);
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withOpacity(0.5),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? colorScheme.primary
                                : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child:
                          isSelected
                              ? Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: colorScheme.onPrimary,
                              )
                              : null,
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 40,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getCardColor(card.cardType),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          _getCardDisplayName(card.cardType),
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                card.maskedCardNumber,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (card.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${card.cardHolderName} • Expires ${card.formattedExpiry}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCardColor(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return const Color(0xFF1A1F71);
      case 'mastercard':
        return const Color(0xFFEB001B);
      case 'amex':
      case 'american express':
        return const Color(0xFF006FCF);
      default:
        return Colors.grey;
    }
  }

  String _getCardDisplayName(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return 'VISA';
      case 'mastercard':
        return 'MC';
      case 'amex':
      case 'american express':
        return 'AMEX';
      default:
        return 'CARD';
    }
  }
}
