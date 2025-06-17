import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/checkout_viewmodel.dart';

class PaymentSecurityInfo extends StatelessWidget {
  const PaymentSecurityInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<CheckoutViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.security_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your payment is secure',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      viewModel.selectedPaymentMethod == 'card'
                          ? 'Your card information is encrypted with 256-bit SSL'
                          : 'Pay cash when your order arrives at your doorstep',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
