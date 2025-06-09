import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../authentication/viewmodels/auth_viewmodel.dart';
import '../../cart/models/cart_item_model.dart';
import '../../cart/services/cart_service.dart';
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
  bool _saveAddress = false;
  final CheckoutService _checkoutService = CheckoutService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserInfo();
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
                        _buildShippingInformation(),
                        const SizedBox(height: 32),
                        _buildPaymentMethods(),
                        if (_selectedPaymentMethod == 'card') ...[
                          const SizedBox(height: 24),
                          _buildPaymentForm(),
                        ],
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

  Widget _buildShippingInformation() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shipping Information',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Name and Email
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Phone
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Address
        TextFormField(
          controller: _addressController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Street Address',
            prefixIcon: const Icon(Icons.home),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // City and Postal Code
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Postal Code',
                  prefixIcon: const Icon(Icons.local_post_office),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter postal code';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Save address checkbox
        Row(
          children: [
            Checkbox(
              value: _saveAddress,
              onChanged: (value) {
                setState(() {
                  _saveAddress = value ?? false;
                });
              },
            ),
            const Text('Save this address for future orders'),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
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
      ],
    );
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

  Widget _buildPaymentForm() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card Information',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Card Number
          TextFormField(
            controller: _cardNumberController,
            decoration: InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
              prefixIcon: const Icon(Icons.credit_card),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberInputFormatter(),
            ],
            validator: (value) {
              if (value == null || value.length < 19) {
                return 'Please enter a valid card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Expiry and CVV
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  decoration: InputDecoration(
                    labelText: 'MM/YY',
                    hintText: '12/25',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryDateInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.length < 5) {
                      return 'Invalid expiry';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: (value) {
                    if (value == null || value.length < 3) {
                      return 'Invalid CVV';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cardholder Name
          TextFormField(
            controller: _cardNameController,
            decoration: InputDecoration(
              labelText: 'Cardholder Name',
              hintText: 'John Doe',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter cardholder name';
              }
              return null;
            },
          ),
        ],
      ),
    );
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

    setState(() {
      _isProcessing = true;
    });
    try {
      // Create shipping address
      final shippingAddress =
          '${_addressController.text}, ${_cityController.text}, ${_postalCodeController.text}';

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
        },
        cardInfo:
            _selectedPaymentMethod == 'card'
                ? {
                  'cardNumber': _cardNumberController.text,
                  'expiry': _expiryController.text,
                  'cvv': _cvvController.text,
                  'cardholderName': _cardNameController.text,
                }
                : null,
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

// Custom input formatters
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
