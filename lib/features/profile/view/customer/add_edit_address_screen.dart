import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../authentication/model/user_model.dart';
import '../../model/address_model.dart';
import '../../viewmodel/store_profile_viewmodel.dart';

class AddEditAddressScreen extends StatefulWidget {
  final UserModel user;
  final AddressModel? address;

  const AddEditAddressScreen({super.key, required this.user, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  late final AnimationController _animationController;
  late final AnimationController _progressAnimationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _progressAnimation;

  int _currentStep = 0;
  final int _totalSteps = 3;

  late final TextEditingController _nameController;
  late final TextEditingController _streetController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _additionalInfoController;

  bool _isDefault = false;
  String? _selectedCountry = 'Iraq';
  String? _selectedState;
  String? _selectedCity;

  final List<String> _countries = ['Iraq'];

  final Map<String, List<String>> _states = {
    'Iraq': [
      'Baghdad',
      'Basra',
      'Nineveh',
      'Erbil',
      'Anbar',
      'Sulaymaniyah',
      'Kirkuk',
      'Diyala',
      'Karbala',
      'Najaf',
      'Wasit',
      'Maysan',
      'Babil',
      'Qadisiyyah',
      'Muthanna',
      'Dhi Qar',
      'Saladin',
      'Dohuk',
    ],
  };

  final Map<String, List<String>> _cities = {
    'Baghdad': [
      'Baghdad',
      'Kadhimiya',
      'Sadr City',
      'New Baghdad',
      'Adhamiyah',
      'Karkh',
      'Rusafa',
      'Abu Ghraib',
      'Mahmudiyah',
      'Taji',
    ],
    'Basra': [
      'Basra',
      'Zubair',
      'Abu Al-Khaseeb',
      'Qurna',
      'Shatt Al-Arab',
      'Faw',
      'Safwan',
      'Umm Qasr',
    ],
    'Nineveh': [
      'Mosul',
      'Hamdaniya',
      'Tal Afar',
      'Sinjar',
      'Sheikhan',
      'Qaraqosh',
      'Bartella',
      'Bashiqa',
    ],
    'Erbil': [
      'Erbil',
      'Shaqlawa',
      'Koya',
      'Makhmur',
      'Rawanduz',
      'Choman',
      'Mergasur',
      'Soran',
    ],
    'Anbar': [
      'Ramadi',
      'Fallujah',
      'Hit',
      'Haditha',
      'Ana',
      'Rawa',
      'Rutba',
      'Qaim',
    ],
    'Sulaymaniyah': [
      'Sulaymaniyah Central',
      'Halabja',
      'Ranya',
      'Dokan',
      'Penjwin',
      'Darbandikhan',
      'Chamchamal',
      'Kalar',
    ],
    'Kirkuk': ['Kirkuk', 'Hawija', 'Daquq', 'Dibis', 'Tuz Khurmatu'],
    'Diyala': [
      'Baqubah',
      'Muqdadiya',
      'Khalis',
      'Balad Ruz',
      'Mandali',
      'Khanaqin',
    ],
    'Karbala': ['Karbala', 'Ain Tamr', 'Hindiya', 'Hur'],
    'Najaf': ['Najaf', 'Kufa', 'Mishkhab', 'Manathera'],
    'Wasit': ['Kut', 'Suwayrah', 'Numaniya', 'Aziziya', 'Badra', 'Hayy'],
    'Maysan': [
      'Amarah',
      'Majar al-Kabir',
      'Qalat Salih',
      'Ali al-Gharbi',
      'Kahla',
      'Midaina',
    ],
    'Babil': ['Hillah', 'Musayyib', 'Mahawil', 'Hashimiya', 'Iskandariya'],
    'Qadisiyyah': ['Diwaniyah', 'Afak', 'Hamza', 'Shamiya', 'Ghamas'],
    'Muthanna': ['Samawah', 'Rumaitha', 'Khidr', 'Warka'],
    'Dhi Qar': [
      'Nasiriyah',
      'Shatrah',
      'Rifai',
      'Qalat Sukkar',
      'Chibayish',
      'Suq al-Shuyukh',
    ],
    'Saladin': [
      'Tikrit',
      'Samarra',
      'Baiji',
      'Shirqat',
      'Tuz',
      'Dujail',
      'Balad',
    ],
    'Dohuk': ['Dohuk', 'Zakho', 'Amadiya', 'Semel', 'Shekhan', 'Bardarash'],
  };

  List<String> get _availableStates {
    return _selectedCountry != null ? (_states[_selectedCountry!] ?? []) : [];
  }

  List<String> get _availableCities {
    return _selectedState != null ? (_cities[_selectedState!] ?? []) : [];
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _nameController = TextEditingController(text: widget.address?.name);
    _streetController = TextEditingController(
      text: widget.address?.streetAddress,
    );
    _postalCodeController = TextEditingController(
      text: widget.address?.postalCode,
    );
    _additionalInfoController = TextEditingController(
      text: widget.address?.additionalInfo,
    );
    _isDefault = widget.address?.isDefault ?? false;
    _selectedCountry = 'Iraq';
    _selectedState = widget.address?.state;
    _selectedCity = widget.address?.city;

    _animationController.forward();
    _updateProgress();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _postalCodeController.dispose();
    _additionalInfoController.dispose();
    _animationController.dispose();
    _progressAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    final progress = (_currentStep + 1) / _totalSteps;
    _progressAnimationController.animateTo(progress);
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _updateProgress();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _updateProgress();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final theme = Theme.of(context);
    final isEditing = widget.address != null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              children: [
                _buildModernHeader(theme, isEditing),

                _buildStepProgress(theme),

                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildBasicInfoStep(theme),
                        _buildLocationStep(theme),
                        _buildConfirmationStep(theme),
                      ],
                    ),
                  ),
                ),

                _buildNavigationBar(theme, viewModel, isEditing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(ThemeData theme, bool isEditing) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isEditing ? Icons.edit_location_alt : Icons.add_location_alt,
                  color: theme.colorScheme.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Edit Address' : 'Add New Address',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEditing
                          ? 'Update your delivery information'
                          : 'Create a new delivery address',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgress(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            isCurrent
                                ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 3,
                                )
                                : null,
                        boxShadow:
                            isActive
                                ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : null,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color:
                                isActive
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.outline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStepTitle(index),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            isActive
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.outline,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0:
        return 'Basic Info';
      case 1:
        return 'Location';
      case 2:
        return 'Confirm';
      default:
        return '';
    }
  }

  Widget _buildBasicInfoStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the name and street details for your address',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          _buildModernTextField(
            controller: _nameController,
            label: 'Address Name',
            hint: 'e.g., Home, Office, Gym',
            icon: Icons.bookmark_border,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name for this address';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildModernTextField(
            controller: _streetController,
            label: 'Street Address',
            hint: 'Enter your complete street address',
            icon: Icons.home,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your street address';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildModernTextField(
            controller: _additionalInfoController,
            label: 'Additional Details (Optional)',
            hint: 'Apartment, suite, floor, landmark, etc.',
            icon: Icons.description,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Details',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your governorate, city, and postal code',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          _buildModernDropdown(
            label: 'Country',
            hint: 'Iraq',
            icon: Icons.flag,
            value: _selectedCountry,
            items: _countries,
            onChanged: (value) {
            },
          ),
          const SizedBox(height: 24),
          _buildModernDropdown(
            label: 'Governorate',
            hint: 'Select Governorate',
            icon: Icons.map,
            value: _selectedState,
            items: _availableStates,
            onChanged: (value) {
              setState(() {
                _selectedState = value;
                _selectedCity = null; // Reset city when state changes
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a governorate';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildModernDropdown(
            label: 'City',
            hint: 'Select City',
            icon: Icons.location_city_outlined,
            value: _selectedCity,
            items: _availableCities,
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a city';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildModernTextField(
            controller: _postalCodeController,
            label: 'Postal Code',
            hint: 'Enter ZIP/Postal code',
            icon: Icons.markunread_mailbox_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter postal code';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirmation',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your address details and set preferences',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Address Preview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_nameController.text.isNotEmpty) ...[
                  _buildPreviewRow(
                    'Name',
                    _nameController.text,
                    Icons.bookmark_border,
                    theme,
                  ),
                ],
                if (_streetController.text.isNotEmpty) ...[
                  _buildPreviewRow(
                    'Street',
                    _streetController.text,
                    Icons.home,
                    theme,
                  ),
                ],
                if (_additionalInfoController.text.isNotEmpty) ...[
                  _buildPreviewRow(
                    'Additional',
                    _additionalInfoController.text,
                    Icons.description,
                    theme,
                  ),
                ],
                if (_selectedState != null) ...[
                  _buildPreviewRow(
                    'Governorate',
                    _selectedState!,
                    Icons.map,
                    theme,
                  ),
                ],
                if (_selectedCity != null) ...[
                  _buildPreviewRow(
                    'City',
                    _selectedCity!,
                    Icons.location_city_outlined,
                    theme,
                  ),
                ],
                if (_postalCodeController.text.isNotEmpty) ...[
                  _buildPreviewRow(
                    'Postal Code',
                    _postalCodeController.text,
                    Icons.markunread_mailbox_outlined,
                    theme,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _isDefault
                        ? theme.colorScheme.primary.withOpacity(0.3)
                        : theme.colorScheme.outline.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        _isDefault
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : theme.colorScheme.outline.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isDefault ? Icons.favorite : Icons.favorite_border,
                    color:
                        _isDefault
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set as Default Address',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use this as your primary delivery address',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() => _isDefault = value);
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines = 1,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                icon,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              errorStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                icon,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            items:
                items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
            onChanged: onChanged,
            validator: validator,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            isExpanded: true,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationBar(
    ThemeData theme,
    ProfileViewModel viewModel,
    bool isEditing,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Previous',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: viewModel.isLoading ? null : _handleNextOrSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child:
                  viewModel.isLoading
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_currentStep < _totalSteps - 1) ...[
                            Text(
                              'Next',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ] else ...[
                            Icon(
                              isEditing ? Icons.update : Icons.save_alt,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEditing ? 'Update Address' : 'Save Address',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextOrSave() {
    if (_currentStep < _totalSteps - 1) {
      if (_validateCurrentStep()) {
        _nextStep();
      }
    } else {
      _saveAddress();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Basic Info
        return _nameController.text.isNotEmpty &&
            _streetController.text.isNotEmpty;
      case 1: // Location
        return _selectedState != null &&
            _selectedCity != null &&
            _postalCodeController.text.isNotEmpty;
      case 2: // Confirmation
        return true;
      default:
        return false;
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<ProfileViewModel>();
    final theme = Theme.of(context);

    final address = AddressModel(
      id: widget.address?.id ?? '',
      name: _nameController.text,
      streetAddress: _streetController.text,
      city: _selectedCity!,
      state: _selectedState!,
      postalCode: _postalCodeController.text,
      country: _selectedCountry!,
      additionalInfo:
          _additionalInfoController.text.isEmpty
              ? null
              : _additionalInfoController.text,
      isDefault: _isDefault,
    );

    String? error;
    if (widget.address != null) {
      error = await viewModel.updateAddress(widget.user, address);
    } else {
      error = await viewModel.addAddress(widget.user, address);
    }

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.address != null
                ? 'Address updated successfully!'
                : 'Address added successfully!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }
}
