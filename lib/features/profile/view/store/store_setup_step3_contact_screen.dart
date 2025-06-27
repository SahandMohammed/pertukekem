import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/store_setup_viewmodel.dart';
import 'widgets/address_form.dart';
import 'widgets/store_preview_card.dart';

class StoreSetupStep3ContactScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const StoreSetupStep3ContactScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<StoreSetupStep3ContactScreen> createState() =>
      _StoreSetupStep3ContactScreenState();
}

class _StoreSetupStep3ContactScreenState
    extends State<StoreSetupStep3ContactScreen>
    with TickerProviderStateMixin {
  final _addressFormKey = GlobalKey<FormBuilderState>();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Consumer<StoreSetupViewmodel>(
      builder: (context, viewModel, child) {
        debugPrint(
          '🎨 UI Rebuild - Current validation state: ${_isFormValid(viewModel)}',
        );

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: const Text('Store Address'),
            centerTitle: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Step 3 of 4',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: StorePreviewCard(
                                storeName: viewModel.storeName,
                                description: viewModel.description,
                                logoFile: viewModel.logoFile,
                                bannerFile: viewModel.bannerFile,
                              ),
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Store Address Information',
                                    style: textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Help customers find your store location',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  AddressForm(
                                    formKey: _addressFormKey,
                                    initialAddress: viewModel.storeAddress,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: widget.onBack,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back, size: 20),
                            const SizedBox(width: 8),
                            const Text('Back'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _isFormValid(viewModel) ? _onNext : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Continue'),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (viewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Processing...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isFormValid(StoreSetupViewmodel viewModel) {
    debugPrint('🔍 _isFormValid Debug:');
    debugPrint('  storeAddress: ${viewModel.storeAddress}');
    debugPrint('  storeAddress.isEmpty: ${viewModel.storeAddress.isEmpty}');
    debugPrint(
      '  storeAddress.isNotEmpty: ${viewModel.storeAddress.isNotEmpty}',
    );
    debugPrint('  state: ${viewModel.storeAddress['state']}');
    debugPrint('  city: ${viewModel.storeAddress['city']}');
    debugPrint('  street: ${viewModel.storeAddress['street']}');
    debugPrint('  country: ${viewModel.storeAddress['country']}');
    debugPrint('  postalCode: ${viewModel.storeAddress['postalCode']}');
    debugPrint('  additionalInfo: ${viewModel.storeAddress['additionalInfo']}');

    final isValid =
        viewModel.storeAddress.isNotEmpty &&
        viewModel.storeAddress['state'] != null &&
        viewModel.storeAddress['city'] != null &&
        viewModel.storeAddress['street'] != null;

    debugPrint('  isValid result: $isValid');
    debugPrint('🔍 End _isFormValid Debug\n');

    return isValid;
  }

  void _onNext() {
    debugPrint('🚀 _onNext called');

    debugPrint('📝 Saving form data...');
    _addressFormKey.currentState?.save();
    final addressData = _addressFormKey.currentState?.value;

    debugPrint('📝 Form data from FormBuilder: $addressData');

    if (addressData != null) {
      debugPrint('📝 Setting store address in viewmodel...');
      context.read<StoreSetupViewmodel>().setStoreAddress(
        Map<String, dynamic>.from(addressData),
      );
      debugPrint('📝 Store address set successfully');
    } else {
      debugPrint('⚠️ Address data is null!');
    }

    debugPrint('🔍 Checking form validity after saving...');
    final isValidAfterSave = _isFormValid(context.read<StoreSetupViewmodel>());

    if (isValidAfterSave) {
      debugPrint('✅ Form is valid, proceeding to next step');
      widget.onNext();
    } else {
      debugPrint('❌ Form is not valid, cannot proceed');
    }
  }
}
