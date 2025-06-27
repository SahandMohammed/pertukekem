import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/checkout_result_model.dart';

class CheckoutSuccessScreen extends StatefulWidget {
  final List<CheckoutResult> orderResults;
  final String paymentMethod;
  final double totalAmount;

  const CheckoutSuccessScreen({
    super.key,
    required this.orderResults,
    required this.paymentMethod,
    required this.totalAmount,
  });

  @override
  State<CheckoutSuccessScreen> createState() => _CheckoutSuccessScreenState();
}

class _CheckoutSuccessScreenState extends State<CheckoutSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _slideController;
  late Animation<double> _confettiAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeOutBack),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _confettiController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final successfulOrders =
        widget.orderResults.where((r) => r.success).toList();
    final failedOrders = widget.orderResults.where((r) => !r.success).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    AnimatedBuilder(
                      animation: _confettiAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _confettiAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              failedOrders.isEmpty
                                  ? Icons.check_rounded
                                  : Icons.warning_rounded,
                              color: colorScheme.onPrimary,
                              size: 60,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    Text(
                      failedOrders.isEmpty
                          ? 'Order Confirmed!'
                          : 'Order Partially Completed',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      failedOrders.isEmpty
                          ? _getSuccessMessage()
                          : 'Some items in your order could not be processed',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    _buildOrderSummaryCard(),

                    const SizedBox(height: 24),

                    if (successfulOrders.isNotEmpty) ...[
                      _buildOrderResultsCard(
                        title: 'Successful Orders',
                        orders: successfulOrders,
                        isSuccess: true,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (failedOrders.isNotEmpty) ...[
                      _buildOrderResultsCard(
                        title: 'Failed Orders',
                        orders: failedOrders,
                        isSuccess: false,
                      ),
                      const SizedBox(height: 24),
                    ],

                    _buildNextStepsCard(),

                    const SizedBox(height: 32),

                    _buildActionButtons(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getSuccessMessage() {
    switch (widget.paymentMethod) {
      case 'cod':
        return 'Your order has been confirmed! Pay cash when delivered to your door.';
      case 'card':
        return 'Payment successful! Your order is being processed.';
      default:
        return 'Thank you for your order!';
    }
  }

  Widget _buildOrderSummaryCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Total',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              Text(
                NumberFormat.currency(symbol: r'$').format(widget.totalAmount),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: colorScheme.onPrimaryContainer.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                widget.paymentMethod == 'cod'
                    ? Icons.local_shipping
                    : Icons.credit_card,
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.paymentMethod == 'cod'
                    ? 'Cash on Delivery'
                    : 'Credit/Debit Card',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderResultsCard({
    required String title,
    required List<CheckoutResult> orders,
    required bool isSuccess,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isSuccess
                ? colorScheme.surfaceVariant.withOpacity(0.3)
                : colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isSuccess
                  ? colorScheme.outline.withOpacity(0.2)
                  : colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? colorScheme.primary : colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? colorScheme.onSurface : colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...orders.map((order) => _buildOrderItem(order, isSuccess)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CheckoutResult order, bool isSuccess) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.listingTitle,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${order.quantity}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                if (!isSuccess && order.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    order.errorMessage!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            NumberFormat.currency(symbol: r'$').format(order.amount),
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepsCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s Next?',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildNextStepItem(
            icon: Icons.email,
            text: 'Order confirmation sent to your email',
          ),
          if (widget.paymentMethod == 'cod') ...[
            _buildNextStepItem(
              icon: Icons.local_shipping,
              text: 'Prepare cash for delivery',
            ),
            _buildNextStepItem(
              icon: Icons.phone,
              text: 'Delivery team will contact you',
            ),
          ] else ...[
            _buildNextStepItem(
              icon: Icons.inventory,
              text: 'Order being prepared for shipping',
            ),
            _buildNextStepItem(
              icon: Icons.track_changes,
              text: 'Track your order in the Orders section',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextStepItem({required IconData icon, required String text}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Continue Shopping',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 20),
                const SizedBox(width: 8),
                Text(
                  'View My Orders',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
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
