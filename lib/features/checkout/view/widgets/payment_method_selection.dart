import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/checkout_viewmodel.dart';

class PaymentMethodSelection extends StatelessWidget {
  const PaymentMethodSelection({super.key});

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
                      Icons.payment_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Choose Payment Method',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _PaymentMethodOption(
                        method: 'card',
                        title: 'Credit/Debit Card',
                        icon: Icons.credit_card_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _PaymentMethodOption(
                        method: 'cod',
                        title: 'Cash on Delivery',
                        icon: Icons.local_atm_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  final String method;
  final String title;
  final IconData icon;

  const _PaymentMethodOption({
    required this.method,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<CheckoutViewModel>(
      builder: (context, viewModel, child) {
        final isSelected = viewModel.selectedPaymentMethod == method;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              viewModel.selectPaymentMethod(method);
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                  width: 1,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                        : null,
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color:
                        isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: textTheme.labelMedium?.copyWith(
                      color:
                          isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
