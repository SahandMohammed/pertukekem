import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/payment_card_viewmodel.dart';
import '../models/payment_card_model.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _setAsDefault = false;
  String _cardType = 'unknown';

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_onCardNumberChanged);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _onCardNumberChanged() {
    final cardNumber = _cardNumberController.text;
    final newCardType = PaymentCard.determineCardType(cardNumber);

    if (newCardType != _cardType) {
      setState(() {
        _cardType = newCardType;
      });
    }
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    final cardViewModel = Provider.of<PaymentCardViewModel>(
      context,
      listen: false,
    );

    final success = await cardViewModel.addCard(
      cardNumber: _cardNumberController.text,
      cardHolderName: _cardHolderController.text,
      expiryMonth: _expiryMonthController.text,
      expiryYear: _expiryYearController.text,
      cvv: _cvvController.text,
      setAsDefault: _setAsDefault,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Return true to indicate success
    } else if (mounted && cardViewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cardViewModel.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Card'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<PaymentCardViewModel>(
        builder: (context, cardViewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card Preview
                  _buildCardPreview(),
                  const SizedBox(height: 32),

                  // Card Number Field
                  _buildCardNumberField(),
                  const SizedBox(height: 16),

                  // Card Holder Name Field
                  _buildCardHolderField(),
                  const SizedBox(height: 16),

                  // Expiry and CVV Row
                  Row(
                    children: [
                      Expanded(child: _buildExpiryMonthField()),
                      const SizedBox(width: 8),
                      Expanded(child: _buildExpiryYearField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildCvvField()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Set as Default Switch
                  _buildDefaultSwitch(),
                  const SizedBox(height: 32),

                  // Save Button
                  _buildSaveButton(cardViewModel),
                  const SizedBox(height: 16),

                  // Disclaimer
                  _buildDisclaimer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardPreview() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: _getCardColors(_cardType),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Type and Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _cardType.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.credit_card, color: Colors.white, size: 32),
            ],
          ),

          const Spacer(),

          // Card Number
          Text(
            _formatCardNumberForDisplay(_cardNumberController.text),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 20),

          // Card Holder and Expiry
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARD HOLDER',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cardHolderController.text.isNotEmpty
                        ? _cardHolderController.text.toUpperCase()
                        : 'YOUR NAME',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'EXPIRES',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_expiryMonthController.text.padLeft(2, '0')}/${_expiryYearController.text}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardNumberField() {
    return TextFormField(
      controller: _cardNumberController,
      decoration: InputDecoration(
        labelText: 'Card Number',
        hintText: '4242 4242 4242 4242',
        prefixIcon: const Icon(Icons.credit_card),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon:
            _cardType != 'unknown'
                ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _cardType.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
                : null,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(19),
        _CardNumberInputFormatter(),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter card number';
        }
        if (!PaymentCardViewModel.isValidCardNumber(value)) {
          return 'Please enter a valid card number';
        }
        return null;
      },
    );
  }

  Widget _buildCardHolderField() {
    return TextFormField(
      controller: _cardHolderController,
      decoration: InputDecoration(
        labelText: 'Card Holder Name',
        hintText: 'John Doe',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter card holder name';
        }
        if (value.length < 2) {
          return 'Please enter a valid name';
        }
        return null;
      },
    );
  }

  Widget _buildExpiryMonthField() {
    return TextFormField(
      controller: _expiryMonthController,
      decoration: InputDecoration(
        labelText: 'Month',
        hintText: '12',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Month required';
        }
        final month = int.tryParse(value);
        if (month == null || month < 1 || month > 12) {
          return 'Invalid month';
        }
        return null;
      },
    );
  }

  Widget _buildExpiryYearField() {
    return TextFormField(
      controller: _expiryYearController,
      decoration: InputDecoration(
        labelText: 'Year',
        hintText: '25',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Year required';
        }
        if (!PaymentCardViewModel.isValidExpiryDate(
          _expiryMonthController.text,
          value,
        )) {
          return 'Invalid/expired';
        }
        return null;
      },
    );
  }

  Widget _buildCvvField() {
    return TextFormField(
      controller: _cvvController,
      decoration: InputDecoration(
        labelText: 'CVV',
        hintText: '123',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'CVV required';
        }
        if (value.length < 3) {
          return 'Invalid CVV';
        }
        return null;
      },
    );
  }

  Widget _buildDefaultSwitch() {
    return Row(
      children: [
        Switch(
          value: _setAsDefault,
          onChanged: (value) {
            setState(() {
              _setAsDefault = value;
            });
          },
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Set as default payment method',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(PaymentCardViewModel cardViewModel) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: cardViewModel.isLoading ? null : _saveCard,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            cardViewModel.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  'Save Card',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 24),
          const SizedBox(height: 8),
          Text(
            'This is a simulation for educational purposes only. No real payment processing occurs.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.amber.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCardNumberForDisplay(String cardNumber) {
    if (cardNumber.isEmpty) {
      return '**** **** **** ****';
    }

    final formatted = PaymentCardViewModel.formatCardNumber(cardNumber);
    final parts = formatted.split(' ');

    // Fill remaining parts with asterisks
    while (parts.length < 4) {
      parts.add('****');
    }

    // Ensure each part is 4 characters
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].length < 4) {
        parts[i] = parts[i].padRight(4, '*');
      }
    }

    return parts.join(' ');
  }

  List<Color> _getCardColors(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return [const Color(0xFF1A1F71), const Color(0xFF1A237E)];
      case 'mastercard':
        return [const Color(0xFFEB001B), const Color(0xFFF79E1B)];
      case 'amex':
      case 'american express':
        return [const Color(0xFF006FCF), const Color(0xFF0077BE)];
      case 'discover':
        return [const Color(0xFFFF6000), const Color(0xFFE55300)];
      default:
        return [const Color(0xFF424242), const Color(0xFF616161)];
    }
  }
}

// Custom input formatter for card number
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length <= 4) {
      return newValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
