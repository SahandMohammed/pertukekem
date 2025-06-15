import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/store_setup_viewmodel.dart';
import 'widgets/business_hours_picker.dart';
import 'widgets/store_preview_card.dart';

/// Store Setup Step 4: Branding & Hours
class StoreSetupStep4Screen extends StatefulWidget {
  final VoidCallback onBack;

  const StoreSetupStep4Screen({super.key, required this.onBack});

  @override
  State<StoreSetupStep4Screen> createState() => _StoreSetupStep4ScreenState();
}

class _StoreSetupStep4ScreenState extends State<StoreSetupStep4Screen>
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
            title: const Text('Branding & Hours'),
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
                    'Step 4 of 4',
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
                                initialValue: viewModel.socialMedia,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Complete Your Store',
                                      style: textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add business hours and social media (optional)',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Business Hours Section
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Business Hours',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Let customers know when you\'re open',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    BusinessHoursPicker(
                                      initialHours: viewModel.businessHours,
                                      onHoursChanged:
                                          viewModel.setBusinessHours,
                                    ),
                                    const SizedBox(height: 32),

                                    // Social Media Section
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.share,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Social Media Links',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Connect your social media accounts',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Facebook
                                    FormBuilderTextField(
                                      name: 'facebook',
                                      decoration: InputDecoration(
                                        labelText: 'Facebook Page',
                                        hintText:
                                            'https://facebook.com/yourstore',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surfaceContainer,
                                        prefixIcon: Icon(
                                          Icons.facebook,
                                          color: const Color(0xFF1877F2),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        _updateSocialMedia(
                                          'facebook',
                                          value ?? '',
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Instagram
                                    FormBuilderTextField(
                                      name: 'instagram',
                                      decoration: InputDecoration(
                                        labelText: 'Instagram Profile',
                                        hintText:
                                            'https://instagram.com/yourstore',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surfaceContainer,
                                        prefixIcon: Icon(
                                          Icons.camera_alt,
                                          color: const Color(0xFFE4405F),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        _updateSocialMedia(
                                          'instagram',
                                          value ?? '',
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Twitter
                                    FormBuilderTextField(
                                      name: 'twitter',
                                      decoration: InputDecoration(
                                        labelText: 'Twitter Profile',
                                        hintText:
                                            'https://twitter.com/yourstore',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surfaceContainer,
                                        prefixIcon: Icon(
                                          Icons.alternate_email,
                                          color: const Color(0xFF1DA1F2),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        _updateSocialMedia(
                                          'twitter',
                                          value ?? '',
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Website
                                    FormBuilderTextField(
                                      name: 'website',
                                      decoration: InputDecoration(
                                        labelText: 'Website',
                                        hintText: 'https://yourstore.com',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surfaceContainer,
                                        prefixIcon: Icon(
                                          Icons.language,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        _updateSocialMedia(
                                          'website',
                                          value ?? '',
                                        );
                                      },
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

              // Sticky CTA buttons
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: Row(
                  children: [
                    // Back button
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
                    // Create Store button
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed:
                            viewModel.canCreateStore && !viewModel.isLoading
                                ? () => _createStore(viewModel)
                                : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child:
                            viewModel.isLoading
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
                                    const Text('Creating...'),
                                  ],
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Create Store'),
                                    const SizedBox(width: 8),
                                    Icon(Icons.check, size: 20),
                                  ],
                                ),
                      ),
                    ),
                  ],
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
                            Text('Creating your store...'),
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

  void _updateSocialMedia(String platform, String url) {
    final viewModel = context.read<StoreSetupViewmodel>();
    final currentSocial = Map<String, String>.from(viewModel.socialMedia);
    if (url.isEmpty) {
      currentSocial.remove(platform);
    } else {
      currentSocial[platform] = url;
    }
    viewModel.setSocialMedia(currentSocial);
  }

  Future<void> _createStore(StoreSetupViewmodel viewModel) async {
    try {
      // Save form data first
      _formKey.currentState?.save();

      // Use createStoreFromForm which handles image uploads and all form data
      await viewModel.createStoreFromForm(context: context);

      if (mounted && viewModel.error == null) {
        // Navigate back to profile or show success
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Store created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted && viewModel.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create store: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
