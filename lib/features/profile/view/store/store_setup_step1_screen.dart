import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/store_setup_viewmodel.dart';
import 'widgets/category_chips.dart';
import 'widgets/store_preview_card.dart';

/// Store Setup Step 1: Store Basics
class StoreSetupStep1Screen extends StatefulWidget {
  final VoidCallback onNext;

  const StoreSetupStep1Screen({super.key, required this.onNext});

  @override
  State<StoreSetupStep1Screen> createState() => _StoreSetupStep1ScreenState();
}

class _StoreSetupStep1ScreenState extends State<StoreSetupStep1Screen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormBuilderState>();
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
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: const Text('Store Basics'),
            centerTitle: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Step 1 of 4',
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
                  // Progress indicator
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
                              color: colorScheme.outline.withOpacity(0.3),
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

                  // Content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: CustomScrollView(
                        slivers: [
                          // Live preview
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

                          // Form content
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: FormBuilder(
                                key: _formKey,
                                initialValue: {
                                  'storeName': viewModel.storeName,
                                  'description': viewModel.description,
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tell us about your store',
                                      style: textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Provide the basic information to get started',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Store Name
                                    FormBuilderTextField(
                                      name: 'storeName',
                                      decoration: InputDecoration(
                                        labelText: 'Store Name *',
                                        hintText: 'Enter your store name',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surfaceContainer,
                                        prefixIcon: const Icon(Icons.store),
                                      ),
                                      validator:
                                          FormBuilderValidators.required(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          viewModel.setStoreName(value);
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Description
                                    FormBuilderTextField(
                                      name: 'description',
                                      decoration: InputDecoration(
                                        labelText: 'Store Description *',
                                        hintText: 'Describe what you sell',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surfaceContainer,
                                        prefixIcon: const Icon(
                                          Icons.description,
                                        ),
                                        alignLabelWithHint: true,
                                      ),
                                      maxLines: 3,
                                      validator:
                                          FormBuilderValidators.required(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          viewModel.setDescription(value);
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // Categories
                                    Text(
                                      'Categories *',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Select categories that best describe your store',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    CategoryChips(
                                      selectedCategories: viewModel.categories,
                                      onCategoriesChanged:
                                          viewModel.setCategories,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Bottom padding for floating button
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Sticky CTA button
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
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

              // Loading overlay
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
    return viewModel.storeName.isNotEmpty &&
        viewModel.description.isNotEmpty &&
        viewModel.categories.isNotEmpty;
  }

  void _onNext() {
    if (_formKey.currentState?.saveAndValidate() == true) {
      widget.onNext();
    }
  }
}
