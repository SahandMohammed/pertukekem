import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/checkout_viewmodel.dart';

class CheckoutStepIndicator extends StatelessWidget {
  const CheckoutStepIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: StepIndicatorItem(
                  stepIndex: index,
                  currentStep: viewModel.currentStep,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class StepIndicatorItem extends StatelessWidget {
  final int stepIndex;
  final int currentStep;

  const StepIndicatorItem({
    super.key,
    required this.stepIndex,
    required this.currentStep,
  });

  static const List<String> _stepLabels = ['Review', 'Delivery', 'Payment'];
  static const List<IconData> _stepIcons = [
    Icons.shopping_cart_rounded,
    Icons.local_shipping_rounded,
    Icons.payment_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isActive = stepIndex == currentStep;
    final isCompleted = stepIndex < currentStep;

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      isCompleted || isActive
                          ? colorScheme.primary
                          : colorScheme.surfaceVariant,
                  shape: BoxShape.circle,
                  boxShadow:
                      isActive
                          ? [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                          : null,
                ),
                child: AnimatedScale(
                  scale: isActive ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : _stepIcons[stepIndex],
                    color:
                        isCompleted || isActive
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _stepLabels[stepIndex],
                style: textTheme.labelSmall?.copyWith(
                  color:
                      isCompleted || isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        if (stepIndex < 2)
          Container(
            height: 2,
            width: 20,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color:
                  isCompleted
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ],
    );
  }
}
