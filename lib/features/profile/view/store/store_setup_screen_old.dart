import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/store_setup_viewmodel.dart';
import 'widgets/address_form.dart';
import 'widgets/business_hours_picker.dart';
import 'widgets/category_chips.dart';
import 'widgets/contact_info_list.dart';
import 'widgets/store_preview_card.dart';

class StoreSetupScreen extends StatefulWidget {
  const StoreSetupScreen({super.key});

  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen>
    with TickerProviderStateMixin {
  final _step1FormKey = GlobalKey<FormBuilderState>();
  final _step2AddressFormKey = GlobalKey<FormBuilderState>();
  final _step3FormKey = GlobalKey<FormBuilderState>();

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
            title: const Text('Create Your Store'),
            centerTitle: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ...List.generate(3, (index) {
                          final isActive = index <= viewModel.currentStep;

                          return Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color:
                                          isActive
                                              ? colorScheme.primary
                                              : colorScheme.outline.withOpacity(
                                                0.3,
                                              ),
                                    ),
                                  ),
                                ),
                                if (index < 2) const SizedBox(width: 8),
                              ],
                            ),
                          );
                        }),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: colorScheme.copyWith(
                                    primary: colorScheme.primary,
                                  ),
                                ),
                                child: Stepper(
                                  currentStep: viewModel.currentStep,
                                  type: StepperType.vertical,
                                  controlsBuilder: (context, details) {
                                    return const SizedBox.shrink(); // Hide default controls
                                  },
                                  onStepTapped: (step) {
                                    if (step <= viewModel.currentStep ||
                                        (step == viewModel.currentStep + 1 &&
                                            viewModel.isStepValid(
                                              viewModel.currentStep,
                                            ))) {
                                      _navigateToStep(step, viewModel);
                                    }
                                  },
                                  steps: [
                                    _buildStep1(
                                      viewModel,
                                      colorScheme,
                                      textTheme,
                                    ),
                                    _buildStep2(
                                      viewModel,
                                      colorScheme,
                                      textTheme,
                                    ),
                                    _buildStep3(
                                      viewModel,
                                      colorScheme,
                                      textTheme,
                                    ),
                                  ],
                                ),
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
                child: _buildActionButton(viewModel, colorScheme),
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

  Step _buildStep1(
    StoreSetupViewmodel viewModel,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isActive = viewModel.currentStep >= 0;
    final isCompleted = viewModel.isStepValid(0);

    return Step(
      title: const Text('Store Basics'),
      content: FormBuilder(
        key: _step1FormKey,
        initialValue: {
          'storeName': viewModel.storeName,
          'description': viewModel.description,
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormBuilderTextField(
              name: 'storeName',
              decoration: InputDecoration(
                labelText: 'Store Name *',
                hintText: 'Enter your store name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainer,
                prefixIcon: const Icon(Icons.store),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(
                  errorText: 'Store name is required',
                ),
                FormBuilderValidators.minLength(3, errorText: 'Name too short'),
                FormBuilderValidators.maxLength(50, errorText: 'Name too long'),
              ]),              onChanged: (value) {
                if (value != viewModel.storeName) {
                  viewModel.setStoreName(value ?? '');
                }
              },
            ),

            const SizedBox(height: 16),

            FormBuilderTextField(
              name: 'description',
              maxLines: 3,
              maxLength: 250,
              decoration: InputDecoration(
                labelText: 'Store Description',
                hintText: 'Tell customers about your store (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainer,
                prefixIcon: const Icon(Icons.description),
              ),              onChanged: (value) {
                if (value != viewModel.description) {
                  viewModel.setDescription(value ?? '');
                }
              },
            ),

            const SizedBox(height: 24),

            CategoryChips(
              selectedCategories: viewModel.categories,
              onCategoriesChanged: viewModel.setCategories,
            ),
          ],
        ),
      ),
      isActive: isActive,
      state: isCompleted ? StepState.complete : StepState.indexed,
    );
  }

  Step _buildStep2(
    StoreSetupViewmodel viewModel,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isActive = viewModel.currentStep >= 1;
    final isCompleted = viewModel.isStepValid(1);

    return Step(
      title: const Text('Contact & Address'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AddressForm(
            formKey: _step2AddressFormKey,
            initialAddress: viewModel.storeAddress,
          ),

          const SizedBox(height: 24),

          ContactInfoList(
            initialContacts: viewModel.contactInfo,
            onContactsChanged: viewModel.setContactInfo,
          ),
        ],
      ),
      isActive: isActive,
      state: isCompleted ? StepState.complete : StepState.indexed,
    );
  }

  Step _buildStep3(
    StoreSetupViewmodel viewModel,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isActive = viewModel.currentStep >= 2;

    return Step(
      title: const Text('Branding & Hours'),
      content: FormBuilder(
        key: _step3FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageUploads(viewModel, colorScheme, textTheme),

            const SizedBox(height: 24),

            BusinessHoursPicker(
              initialHours: viewModel.businessHours,
              onHoursChanged: viewModel.setBusinessHours,
            ),

            const SizedBox(height: 24),

            _buildSocialMediaFields(viewModel, colorScheme, textTheme),
          ],
        ),
      ),
      isActive: isActive,
      state: StepState.indexed,
    );
  }

  Widget _buildImageUploads(
    StoreSetupViewmodel viewModel,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Store Images',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Add a logo and banner to make your store stand out',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildImageUploadButton(
                label: 'Store Logo',
                subtitle: '512x512 recommended',
                file: viewModel.logoFile,
                onTap: viewModel.selectLogo,
                colorScheme: colorScheme,
                icon: Icons.store,
                heroTag: 'store_logo',
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _buildImageUploadButton(
                label: 'Store Banner',
                subtitle: '1024x512 recommended',
                file: viewModel.bannerFile,
                onTap: viewModel.selectBanner,
                colorScheme: colorScheme,
                icon: Icons.image,
                heroTag: 'store_banner',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageUploadButton({
    required String label,
    required String subtitle,
    required File? file,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required IconData icon,
    required String heroTag,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.5),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surfaceContainer,
        ),
        child:
            file != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Hero(
                    tag: heroTag,
                    child: Image.file(
                      file,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 32, color: colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildSocialMediaFields(
    StoreSetupViewmodel viewModel,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Social Media (Optional)',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect your social media accounts',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),

        FormBuilderTextField(
          name: 'facebook',
          decoration: InputDecoration(
            labelText: 'Facebook Page',
            hintText: 'https://facebook.com/yourstore',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: colorScheme.surfaceContainer,
            prefixIcon: const Icon(Icons.facebook),
          ),
          keyboardType: TextInputType.url,          onChanged: (value) {
            final social = Map<String, String>.from(viewModel.socialMedia);
            final currentFacebook = social['facebook'];
            
            if (value?.isNotEmpty == true) {
              if (currentFacebook != value) {
                social['facebook'] = value!;
                viewModel.setSocialMedia(social);
              }
            } else if (currentFacebook != null) {
              social.remove('facebook');
              viewModel.setSocialMedia(social);
            }
          },
        ),

        const SizedBox(height: 16),

        FormBuilderTextField(
          name: 'instagram',
          decoration: InputDecoration(
            labelText: 'Instagram',
            hintText: '@yourstorehandle',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: colorScheme.surfaceContainer,
            prefixIcon: const Icon(Icons.camera_alt),
          ),          onChanged: (value) {
            final social = Map<String, String>.from(viewModel.socialMedia);
            final currentInstagram = social['instagram'];
            
            if (value?.isNotEmpty == true) {
              if (currentInstagram != value) {
                social['instagram'] = value!;
                viewModel.setSocialMedia(social);
              }
            } else if (currentInstagram != null) {
              social.remove('instagram');
              viewModel.setSocialMedia(social);
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    StoreSetupViewmodel viewModel,
    ColorScheme colorScheme,
  ) {
    final isLastStep = viewModel.currentStep == 2;
    final canProceed = viewModel.isStepValid(viewModel.currentStep);

    return Row(
      children: [
        if (viewModel.currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _navigateToStep(viewModel.currentStep - 1, viewModel);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back'),
            ),
          ),

        if (viewModel.currentStep > 0) const SizedBox(width: 16),

        Expanded(
          flex: viewModel.currentStep > 0 ? 2 : 1,
          child: ElevatedButton.icon(
            onPressed:
                canProceed
                    ? () {
                      if (isLastStep) {
                        _createStore(viewModel);
                      } else {
                        _proceedToNextStep(viewModel);
                      }
                    }
                    : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            icon: Icon(isLastStep ? Icons.store : Icons.arrow_forward),
            label: Text(isLastStep ? 'Create Store' : 'Next'),
          ),
        ),
      ],
    );
  }

  void _navigateToStep(int step, StoreSetupViewmodel viewModel) {
    _fadeController.reset();
    viewModel.setCurrentStep(step);
    _fadeController.forward();
  }

  void _proceedToNextStep(StoreSetupViewmodel viewModel) {
    _saveCurrentStepData(viewModel);

    if (viewModel.isStepValid(viewModel.currentStep)) {
      _navigateToStep(viewModel.currentStep + 1, viewModel);
    }
  }

  void _saveCurrentStepData(StoreSetupViewmodel viewModel) {
    switch (viewModel.currentStep) {
      case 0:
        _step1FormKey.currentState?.save();
        break;
      case 1:
        _step2AddressFormKey.currentState?.save();
        final addressData = _step2AddressFormKey.currentState?.value;
        if (addressData != null) {
          viewModel.setStoreAddress(Map<String, dynamic>.from(addressData));
        }
        break;
      case 2:
        _step3FormKey.currentState?.save();
        break;
    }
  }

  void _createStore(StoreSetupViewmodel viewModel) async {
    _saveCurrentStepData(viewModel);

    await viewModel.createStoreFromForm(context: context);

    if (viewModel.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Store created successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pop();
      }
    }
  }
}
