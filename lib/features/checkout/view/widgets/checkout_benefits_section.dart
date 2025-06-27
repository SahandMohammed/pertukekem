import 'package:flutter/material.dart';

class CheckoutBenefitsSection extends StatelessWidget {
  const CheckoutBenefitsSection({super.key});

  static const List<Map<String, dynamic>> _benefits = [
    {
      'icon': Icons.security_rounded,
      'title': 'Secure Payment',
      'subtitle': '256-bit SSL encryption',
    },
    {
      'icon': Icons.local_shipping_rounded,
      'title': 'Free Shipping',
      'subtitle': 'On all orders over \$25',
    },
    {
      'icon': Icons.support_agent_rounded,
      'title': '24/7 Support',
      'subtitle': 'Customer service available',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why shop with us?',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._benefits.map(
          (benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    benefit['icon'] as IconData,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        benefit['title'] as String,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        benefit['subtitle'] as String,
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
      ],
    );
  }
}
