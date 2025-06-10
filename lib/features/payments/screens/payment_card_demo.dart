import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/payment_card_viewmodel.dart';
import '../models/payment_card_model.dart';

class PaymentCardDemo extends StatelessWidget {
  const PaymentCardDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Card Demo'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo Header
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade700,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Payment Card Demo - FYP Project',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This is a simulation for educational purposes only. No real payment processing occurs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Add Test Cards Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.credit_card, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Add Test Cards',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Use these test card numbers for demonstration:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    // Test Card Examples
                    ..._buildTestCardExamples(context),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _addSampleCards(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add All Sample Cards'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card Statistics
            Consumer<PaymentCardViewModel>(
              builder: (context, cardViewModel, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Card Statistics',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                'Total Cards',
                                '${cardViewModel.cards.length}',
                                Icons.credit_card,
                                Colors.blue,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                'Default Card',
                                cardViewModel.defaultCard != null ? '1' : '0',
                                Icons.star,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (cardViewModel.cards.isNotEmpty) ...[
                          const Text(
                            'Card Types:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children:
                                _getCardTypes(cardViewModel.cards)
                                    .map(
                                      (type) => Chip(
                                        label: Text(type.toUpperCase()),
                                        backgroundColor: _getCardTypeColor(
                                          type,
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],

                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => cardViewModel.loadCards(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Data'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Features Showcase
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.featured_play_list,
                          color: Colors.purple.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Features Implemented',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ..._buildFeatureList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTestCardExamples(BuildContext context) {
    final testCards = [
      {
        'name': 'Visa Test Card',
        'number': '4242 4242 4242 4242',
        'expiry': '12/28',
        'cvv': '123',
      },
      {
        'name': 'Mastercard Test Card',
        'number': '5555 5555 5555 4444',
        'expiry': '10/27',
        'cvv': '456',
      },
      {
        'name': 'American Express',
        'number': '3782 822463 10005',
        'expiry': '09/26',
        'cvv': '7890',
      },
    ];

    return testCards
        .map(
          (card) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card['name']!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text('Number: ${card['number']!}'),
                Text('Expiry: ${card['expiry']!} | CVV: ${card['cvv']!}'),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
  List<String> _getCardTypes(List<PaymentCard> cards) {
    return cards.map((card) => card.cardType).toSet().toList();
  }

  Color _getCardTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
        return Colors.blue.shade100;
      case 'mastercard':
        return Colors.orange.shade100;
      case 'amex':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  List<Widget> _buildFeatureList() {
    final features = [
      '✅ Add new payment cards',
      '✅ Set default card',
      '✅ Delete cards with confirmation',
      '✅ Card type auto-detection',
      '✅ Expiry date validation',
      '✅ Firebase Firestore integration',
      '✅ Provider state management',
      '✅ Responsive UI design',
      '✅ Error handling',
      '✅ Loading states',
    ];

    return features
        .map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(feature, style: const TextStyle(fontSize: 14)),
          ),
        )
        .toList();
  }

  Future<void> _addSampleCards(BuildContext context) async {
    final cardViewModel = Provider.of<PaymentCardViewModel>(
      context,
      listen: false,
    );

    final sampleCards = [
      {
        'number': '4242424242424242',
        'holder': 'John Doe',
        'month': '12',
        'year': '28',
        'cvv': '123',
        'default': true,
      },
      {
        'number': '5555555555554444',
        'holder': 'Jane Smith',
        'month': '10',
        'year': '27',
        'cvv': '456',
        'default': false,
      },
      {
        'number': '378282246310005',
        'holder': 'Bob Johnson',
        'month': '09',
        'year': '26',
        'cvv': '7890',
        'default': false,
      },
    ];

    bool hasError = false;
    String errorMessage = '';

    for (int i = 0; i < sampleCards.length; i++) {
      final card = sampleCards[i];
      final success = await cardViewModel.addCard(
        cardNumber: card['number']! as String,
        cardHolderName: card['holder']! as String,
        expiryMonth: card['month']! as String,
        expiryYear: card['year']! as String,
        cvv: card['cvv']! as String,
        setAsDefault: i == 0, // Only first card as default
      );

      if (!success) {
        hasError = true;
        errorMessage = cardViewModel.error ?? 'Unknown error';
        break;
      }
    }

    if (!hasError && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample cards added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding cards: $errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
