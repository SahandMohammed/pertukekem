import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/store_setup_viewmodel.dart';
import 'store_setup_step1_screen.dart';
import 'store_setup_step2_screen.dart';
import 'store_setup_step3_screen.dart';

/// Main Store Setup Screen that coordinates navigation between steps
class StoreSetupScreen extends StatefulWidget {
  const StoreSetupScreen({super.key});

  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StoreSetupViewmodel(),
      child: Consumer<StoreSetupViewmodel>(
        builder: (context, viewModel, child) {
          return PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StoreSetupStep1Screen(
                onNext: () => _navigateToStep(1, viewModel),
              ),
              StoreSetupStep2Screen(
                onNext: () => _navigateToStep(2, viewModel),
                onBack: () => _navigateToStep(0, viewModel),
              ),
              StoreSetupStep3Screen(
                onBack: () => _navigateToStep(1, viewModel),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToStep(int step, StoreSetupViewmodel viewModel) {
    viewModel.setCurrentStep(step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
