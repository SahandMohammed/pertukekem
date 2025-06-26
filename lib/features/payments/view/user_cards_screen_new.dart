import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/payment_card_model.dart';
import '../viewmodel/payment_card_viewmodel.dart';
import 'add_card_screen.dart';

class UserCardsScreen extends StatefulWidget {
  const UserCardsScreen({super.key});

  @override
  State<UserCardsScreen> createState() => _UserCardsScreenState();
}

class _UserCardsScreenState extends State<UserCardsScreen> {
  @override
  void initState() {
    super.initState();
    // Load cards when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentCardViewModel>(context, listen: false).loadCards();
    });
  }

  Future<void> _navigateToAddCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCardScreen()),
    );

    // If card was added successfully, reload cards
    if (result == true && mounted) {
      Provider.of<PaymentCardViewModel>(context, listen: false).loadCards();
    }
  }

  Future<void> _setDefaultCard(
    String cardId,
    PaymentCardViewModel cardViewModel,
  ) async {
    final success = await cardViewModel.setCardAsDefault(cardId);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Default card updated')));
    } else if (!success && mounted && cardViewModel.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${cardViewModel.error}')));
    }
  }

  Future<void> _deleteCard(
    String cardId,
    PaymentCardViewModel cardViewModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Card'),
            content: const Text('Are you sure you want to remove this card?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await cardViewModel.deleteCard(cardId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card removed successfully')),
        );
      } else if (!success && mounted && cardViewModel.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${cardViewModel.error}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cards'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<PaymentCardViewModel>(
                context,
                listen: false,
              ).loadCards();
            },
          ),
        ],
      ),
      body: Consumer<PaymentCardViewModel>(
        builder: (context, cardViewModel, child) {
          return _buildBody(cardViewModel);
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "user_cards_new_fab",
        onPressed: _navigateToAddCard,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(PaymentCardViewModel cardViewModel) {
    if (cardViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cardViewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Error: ${cardViewModel.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => cardViewModel.loadCards(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (cardViewModel.cards.isEmpty) {
      return _buildEmptyState();
    }

    return _buildCardsList(cardViewModel);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No saved cards',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a card to get started with secure payments',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddCard,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Card'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList(PaymentCardViewModel cardViewModel) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cardViewModel.cards.length,
      itemBuilder: (context, index) {
        final card = cardViewModel.cards[index];
        return _buildCardItem(card, cardViewModel);
      },
    );
  }

  Widget _buildCardItem(PaymentCard card, PaymentCardViewModel cardViewModel) {
    final isExpired = card.isExpired;
    final isExpiringSoon = card.isExpiringSoon;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: _getCardColors(card.cardType),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header with type and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getCardIcon(card.cardType),
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      card.cardType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'default':
                        _setDefaultCard(card.id, cardViewModel);
                        break;
                      case 'delete':
                        _deleteCard(card.id, cardViewModel);
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        if (!card.isDefault)
                          const PopupMenuItem(
                            value: 'default',
                            child: Row(
                              children: [
                                Icon(Icons.star_outline),
                                SizedBox(width: 8),
                                Text('Set as Default'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Remove Card',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card number (masked)
            Text(
              '**** **** **** ${card.lastFourDigits}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),

            // Card holder and expiry
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARD HOLDER',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.cardHolderName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'EXPIRES',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${card.expiryMonth.toString().padLeft(2, '0')}/${card.expiryYear.toString().substring(2)}',
                      style: TextStyle(
                        color: isExpired ? Colors.red.shade200 : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Status indicators
            Row(
              children: [
                if (card.isDefault) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Default',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Expired',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else if (isExpiringSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Expires Soon',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getCardColors(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return [const Color(0xFF1A1F71), const Color(0xFF1A237E)];
      case 'mastercard':
        return [const Color(0xFFEB001B), const Color(0xFFF79E1B)];
      case 'amex':
      case 'american express':
        return [const Color(0xFF006FCF), const Color(0xFF0077BE)];
      case 'discover':
        return [const Color(0xFFFF6000), const Color(0xFFE55300)];
      default:
        return [const Color(0xFF424242), const Color(0xFF616161)];
    }
  }

  IconData _getCardIcon(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
      case 'american express':
        return Icons.credit_card;
      case 'discover':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }
}
