import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/checkout_viewmodel.dart';
import '../../../profile/model/address_model.dart';

class AddressOptionItem extends StatelessWidget {
  final AddressModel address;

  const AddressOptionItem({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<CheckoutViewModel>(
      builder: (context, viewModel, child) {
        final isSelected = viewModel.selectedAddress?.id == address.id;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => viewModel.selectAddress(address),
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
                    _buildSelectionIndicator(context, isSelected),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAddressInfo(context)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionIndicator(BuildContext context, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.outline,
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
    );
  }

  Widget _buildAddressInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              address.name,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (address.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        const SizedBox(height: 4),
        Text(
          address.fullAddress,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
