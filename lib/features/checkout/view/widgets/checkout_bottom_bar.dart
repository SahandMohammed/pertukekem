import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../cart/model/cart_item_model.dart';
import '../../viewmodel/checkout_viewmodel.dart';

class CheckoutBottomBar extends StatelessWidget {
  final Cart cart;
  final PageController pageController;

  const CheckoutBottomBar({
    super.key,
    required this.cart,
    required this.pageController,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<CheckoutViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (viewModel.currentStep > 0) ...[
                  OutlinedButton(
                    onPressed:
                        viewModel.isProcessing
                            ? null
                            : () {
                              viewModel.previousStep();
                              pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child:
                        viewModel.currentStep < 2
                            ? _ContinueButton(
                              key: ValueKey(
                                'continue-${viewModel.currentStep}',
                              ),
                              viewModel: viewModel,
                              pageController: pageController,
                            )
                            : _PlaceOrderButton(
                              key: const ValueKey('place-order'),
                              viewModel: viewModel,
                              cart: cart,
                            ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final CheckoutViewModel viewModel;
  final PageController pageController;

  const _ContinueButton({
    super.key,
    required this.viewModel,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FilledButton(
      onPressed:
          viewModel.canProceedToNextStep() ? () => _proceedToNextStep() : null,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            viewModel.currentStep == 0
                ? 'Continue to Delivery'
                : 'Continue to Payment',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_rounded,
            color: colorScheme.onPrimary,
            size: 20,
          ),
        ],
      ),
    );
  }

  void _proceedToNextStep() {
    if (viewModel.currentStep < 2) {
      viewModel.nextStep();
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}

class _PlaceOrderButton extends StatelessWidget {
  final CheckoutViewModel viewModel;
  final Cart cart;

  const _PlaceOrderButton({
    super.key,
    required this.viewModel,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FilledButton(
      onPressed:
          viewModel.canPlaceOrder() && !viewModel.isProcessing
              ? () => _processOrder(context)
              : null,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child:
          viewModel.isProcessing
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Processing...',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Place Order • ${NumberFormat.currency(symbol: r'$').format(cart.totalAmount)}',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
    );
  }

  Future<void> _processOrder(BuildContext context) async {
    try {
      final results = await viewModel.processOrder(cart);

      if (context.mounted) {
        // TODO: Navigate to checkout success screen
        // This navigation will be implemented when the navigation is refactored
        debugPrint('Order processed successfully: $results');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process order: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
