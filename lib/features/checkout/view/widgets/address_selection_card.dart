import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/checkout_viewmodel.dart';
import '../../../profile/model/address_model.dart';
import '../../../authentication/viewmodel/auth_viewmodel.dart';
import '../../../profile/viewmodel/store_profile_viewmodel.dart';
import '../../../profile/view/customer/manage_address_screen.dart';
import 'address_option_item.dart';

class AddressSelectionCard extends StatelessWidget {
  const AddressSelectionCard({super.key});

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
              _buildHeader(context),
              ...viewModel.userAddresses.map(
                (address) => AddressOptionItem(address: address),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
          Icon(Icons.location_on_rounded, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Select Delivery Address',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _navigateToManageAddresses(context),
            icon: const Icon(Icons.settings_rounded, size: 16),
            label: const Text('Manage'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
