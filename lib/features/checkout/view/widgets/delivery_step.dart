import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/checkout_viewmodel.dart';
import 'address_selection_card.dart';
import 'delivery_options_card.dart';
import 'loading_card.dart';
import 'empty_address_card.dart';

class DeliveryStep extends StatelessWidget {
  const DeliveryStep({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<CheckoutViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Address',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Where should we deliver your books?',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (viewModel.isLoadingAddresses)
                const LoadingCard(message: 'Loading addresses...')
              else if (viewModel.userAddresses.isEmpty)
                const EmptyAddressCard()
              else
                const AddressSelectionCard(),
              const SizedBox(height: 32),
              const DeliveryOptionsCard(),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }
}
