import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/checkout_viewmodel.dart';
import '../../../authentication/viewmodel/auth_viewmodel.dart';
import '../../../profile/viewmodel/store_profile_viewmodel.dart';
import '../../../profile/view/customer/manage_address_screen.dart';

class EmptyAddressCard extends StatelessWidget {
  const EmptyAddressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off_rounded,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Delivery Address',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'You need to add a delivery address to proceed with your order.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _navigateToManageAddresses(context),
            icon: const Icon(Icons.add_location_alt_rounded),
            label: const Text('Add Address'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToManageAddresses(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChangeNotifierProvider(
              create: (context) {
                final profileViewModel = ProfileViewModel();
                profileViewModel.setAuthViewModel(
                  context.read<AuthViewModel>(),
                );
                return profileViewModel;
              },
              child: const ManageAddressScreen(),
            ),
      ),
    );

    if (result != null && context.mounted) {
      context.read<CheckoutViewModel>().refreshAddresses();
    }
  }
}
