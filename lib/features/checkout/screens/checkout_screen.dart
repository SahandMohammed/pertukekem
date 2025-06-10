import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../authentication/viewmodels/auth_viewmodel.dart';
import '../../cart/models/cart_item_model.dart';
import '../../cart/services/cart_service.dart';
import '../../profile/models/address_model.dart';
import '../../profile/viewmodels/profile_viewmodel.dart';
import '../../profile/screens/manage_address_screen.dart';
import '../../payments/models/payment_card_model.dart';
import '../../payments/viewmodels/payment_card_viewmodel.dart';
import '../../payments/screens/user_cards_screen.dart';
import '../services/checkout_service.dart';
import 'checkout_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Cart cart;

  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // Payment form controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardNameController = TextEditingController();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;
  final CheckoutService _checkoutService = CheckoutService();

  // Address and Payment Card related
  List<AddressModel> _userAddresses = [];
  List<PaymentCard> _userCards = [];
  AddressModel? _selectedAddress;
  PaymentCard? _selectedCard;
  bool _isLoadingAddresses = false;
  bool _isLoadingCards = false;
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserInfo();
    _loadUserAddresses();
    _loadUserCards();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  void _loadUserInfo() {
    final user = context.read<AuthViewModel>().user;
    if (user != null) {
      _nameController.text = '${user.firstName} ${user.lastName}';
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber;
    }
  }

  Future<void> _loadUserAddresses() async {
    final user = context.read<AuthViewModel>().user;
    if (user == null) return;

    setState(() {
      _isLoadingAddresses = true;
    });

    try {
      final profileViewModel = context.read<ProfileViewModel>();
      profileViewModel.setAuthViewModel(context.read<AuthViewModel>());
      await profileViewModel.loadAddresses(user);

      setState(() {
        _userAddresses = profileViewModel.addresses;
        // Auto-select default address if available
        _selectedAddress =
            _userAddresses.isNotEmpty
                ? _userAddresses.firstWhere(
                  (addr) => addr.isDefault,
                  orElse: () => _userAddresses.first,
                )
                : null;
      });
    } catch (e) {
      debugPrint('Error loading addresses: $e');
    } finally {
      setState(() {
        _isLoadingAddresses = false;
      });
    }
  }

  Future<void> _loadUserCards() async {
    setState(() {
      _isLoadingCards = true;
    });

    try {
      final cardViewModel = context.read<PaymentCardViewModel>();
      await cardViewModel.loadCards();

      setState(() {
        _userCards = cardViewModel.cards;
        // Auto-select default card if available
        _selectedCard =
            _userCards.isNotEmpty
                ? _userCards.firstWhere(
                  (card) => card.isDefault,
                  orElse: () => _userCards.first,
                )
                : null;
      });
    } catch (e) {
      debugPrint('Error loading cards: $e');
    } finally {
      setState(() {
        _isLoadingCards = false;
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderSummary(),
                        const SizedBox(height: 32),
                        _buildAddressSelection(),
                        const SizedBox(height: 32),
                        _buildPaymentSelection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: colorScheme.onPrimaryContainer,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Order Summary',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items list
          ...widget.cart.items.map((item) => _buildOrderItem(item)),

          const SizedBox(height: 16),
          Container(
            height: 1,
            color: colorScheme.onPrimaryContainer.withOpacity(0.2),
          ),
          const SizedBox(height: 16),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total (${widget.cart.totalItems} items)',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              Text(
                NumberFormat.currency(
                  symbol: r'$',
                ).format(widget.cart.totalAmount),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image:
                  item.listing.coverUrl.isNotEmpty
                      ? DecorationImage(
                        image: NetworkImage(item.listing.coverUrl),
                        fit: BoxFit.cover,
                      )
                      : null,
              color:
                  item.listing.coverUrl.isEmpty
                      ? colorScheme.surfaceVariant
                      : null,
            ),
            child:
                item.listing.coverUrl.isEmpty
                    ? Icon(Icons.book, color: colorScheme.onSurfaceVariant)
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.listing.title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Text(
            NumberFormat.currency(symbol: r'$').format(item.totalPrice),
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSelection() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery Address',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _navigateToManageAddresses(),
              icon: Icon(Icons.settings, size: 18),
              label: Text('Manage'),
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoadingAddresses)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text('Loading addresses...'),
              ],
            ),
          )
        else if (_userAddresses.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(Icons.location_off, size: 48, color: colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'No saved addresses',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add an address to continue with checkout',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _navigateToManageAddresses(),
                  icon: Icon(Icons.add_location),
                  label: Text('Add Address'),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                DropdownButtonFormField<AddressModel>(
                  value: _selectedAddress,
                  decoration: InputDecoration(
                    labelText: 'Select Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items:
                      _userAddresses.map((address) {
                        return DropdownMenuItem<AddressModel>(
                          value: address,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    address.name,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (address.isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Default',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onPrimary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                address.fullAddress,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (AddressModel? newAddress) {
                    setState(() {
                      _selectedAddress = newAddress;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a delivery address';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentSelection() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Method',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedPaymentMethod == 'card')
              TextButton.icon(
                onPressed: () => _navigateToManageCards(),
                icon: Icon(Icons.settings, size: 18),
                label: Text('Manage'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Payment Method Selection
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodCard(
                'card',
                'Credit/Debit Card',
                Icons.credit_card,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPaymentMethodCard(
                'cod',
                'Cash on Delivery',
                Icons.local_shipping,
              ),
            ),
          ],
        ),

        if (_selectedPaymentMethod == 'card') ...[
          const SizedBox(height: 24),

          if (_isLoadingCards)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text('Loading payment cards...'),
                ],
              ),
            )
          else if (_userCards.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.credit_card_off,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No saved cards',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a payment card to continue with checkout',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToManageCards(),
                    icon: Icon(Icons.add_card),
                    label: Text('Add Card'),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Payment Card',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cards list
                  ...(_userCards.map((card) => _buildCardOption(card))),

                  const SizedBox(height: 16),

                  // CVV input for selected card
                  if (_selectedCard != null) ...[
                    TextFormField(
                      controller: _cvvController,
                      decoration: InputDecoration(
                        labelText: 'CVV for ${_selectedCard!.maskedCardNumber}',
                        hintText: '123',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (value) {
                        if (value == null || value.length < 3) {
                          return 'Please enter CVV';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildCardOption(PaymentCard card) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _selectedCard?.id == card.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCard = card;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 25,
                decoration: BoxDecoration(
                  color: _getCardColor(card.cardType),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    _getCardDisplayName(card.cardType),
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.maskedCardNumber,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${card.cardHolderName} • Expires ${card.formattedExpiry}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (card.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Default',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCardColor(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return const Color(0xFF1A1F71);
      case 'mastercard':
        return const Color(0xFFEB001B);
      case 'amex':
        return const Color(0xFF006FCF);
      case 'discover':
        return const Color(0xFFFF6000);
      default:
        return Colors.grey;
    }
  }

  String _getCardDisplayName(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return 'VISA';
      case 'mastercard':
        return 'MC';
      case 'amex':
        return 'AMEX';
      case 'discover':
        return 'DISC';
      default:
        return 'CARD';
    }
  }

  Widget _buildPaymentMethodCard(String method, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _selectedPaymentMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: textTheme.labelMedium?.copyWith(
                color:
                    isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToManageAddresses() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChangeNotifierProvider(
              create: (context) {
                final profileViewModel = ProfileViewModel();
                profileViewModel.setAuthViewModel(
                  context.read<AuthViewModel>(),
                );
                return profileViewModel;
              },
              child: const ManageAddressScreen(),
            ),
      ),
    );

    // Reload addresses when returning
    if (result != null && mounted) {
      _loadUserAddresses();
    }
  }

  Future<void> _navigateToManageCards() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserCardsScreen()),
    );

    // Reload cards when returning
    if (result != null && mounted) {
      _loadUserCards();
    }
  }

  Widget _buildBottomSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Security notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedPaymentMethod == 'card'
                          ? 'Your payment information is encrypted and secure'
                          : 'Pay cash when your order is delivered to your door',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Place Order Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child:
                    _isProcessing
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
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
                              _selectedPaymentMethod == 'card'
                                  ? Icons.lock
                                  : Icons.local_shipping,
                              size: 20,
                              color: colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Place Order - ${NumberFormat.currency(symbol: r'$').format(widget.cart.totalAmount)}',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (authViewModel.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to continue')),
      );
      return;
    }

    // Validate required selections
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    if (_selectedPaymentMethod == 'card' && _selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment card')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Use selected address
      final shippingAddress = _selectedAddress!.fullAddress;

      // Prepare card info if using card payment
      Map<String, String>? cardInfo;
      if (_selectedPaymentMethod == 'card' && _selectedCard != null) {
        cardInfo = {
          'cardId': _selectedCard!.id,
          'cardType': _selectedCard!.cardType,
          'lastFourDigits': _selectedCard!.lastFourDigits,
          'cardholderName': _selectedCard!.cardHolderName,
          'expiry':
              '${_selectedCard!.expiryMonth}/${_selectedCard!.expiryYear}',
        };
      }

      // Process each item in the cart
      final results = await _checkoutService.processCartCheckout(
        cart: widget.cart,
        buyerId: authViewModel.user!.userId,
        paymentMethod: _selectedPaymentMethod,
        shippingAddress: shippingAddress,
        customerInfo: {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'addressId': _selectedAddress!.id,
          'selectedCardId': _selectedCard?.id ?? '',
        },
        cardInfo: cardInfo,
      );

      // Clear cart after successful processing
      final cartService = context.read<CartService>();
      await cartService.clearCart();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => CheckoutSuccessScreen(
                  orderResults: results,
                  paymentMethod: _selectedPaymentMethod,
                  totalAmount: widget.cart.totalAmount,
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
