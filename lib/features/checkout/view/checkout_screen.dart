import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/viewmodel/auth_viewmodel.dart';
import '../../cart/model/cart_item_model.dart';
import '../../cart/services/cart_service.dart';
import '../../profile/viewmodel/store_profile_viewmodel.dart';
import '../../payments/viewmodel/payment_card_viewmodel.dart';
import '../viewmodel/checkout_viewmodel.dart';
import 'widgets/checkout_app_bar.dart';
import 'widgets/checkout_step_indicator.dart';
import 'widgets/order_review_step.dart';
import 'widgets/delivery_step.dart';
import 'widgets/payment_step.dart';
import 'widgets/checkout_bottom_bar.dart';

class CheckoutScreen extends StatefulWidget {
  final Cart cart;

  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController(initialPage: 0);

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeViewModel();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeViewModel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final checkoutViewModel = context.read<CheckoutViewModel>();

      // Reset checkout state to ensure we start from step 0
      checkoutViewModel.resetToInitialState();

      // Reset page controller to page 0
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }

      checkoutViewModel.setDependencies(
        authViewModel: context.read<AuthViewModel>(),
        profileViewModel: context.read<ProfileViewModel>(),
        paymentCardViewModel: context.read<PaymentCardViewModel>(),
        cartService: context.read<CartService>(),
      );
      checkoutViewModel.loadInitialData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<CheckoutViewModel>(
      builder: (context, checkoutViewModel, child) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  CheckoutAppBar(cart: widget.cart),
                  const CheckoutStepIndicator(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: checkoutViewModel.setCurrentStep,
                      children: [
                        OrderReviewStep(cart: widget.cart),
                        const DeliveryStep(),
                        const PaymentStep(),
                      ],
                    ),
                  ),
                  CheckoutBottomBar(
                    cart: widget.cart,
                    pageController: _pageController,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
