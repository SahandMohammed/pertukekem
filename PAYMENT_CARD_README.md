# Payment Card Management System - FYP Implementation

## Overview

This is a complete implementation of a simulated credit/debit card storage feature for a Flutter application using Firebase Firestore and Provider for state management. This system is designed for educational purposes as part of a Final Year Project (FYP).

**⚠️ IMPORTANT: This is for educational/simulation purposes only. No real payment processing occurs and no sensitive financial data should be used.**

## Features Implemented

### 1. Data Model (`PaymentCard`)

- **Location**: `lib/features/payments/models/payment_card_model.dart`
- **Fields**:
  - `id`: Unique identifier
  - `userId`: Reference to the user who owns the card
  - `cardHolderName`: Name on the card
  - `lastFourDigits`: Last 4 digits of the card (for display)
  - `cardType`: Auto-detected type (Visa, Mastercard, Amex, etc.)
  - `expiryMonth` & `expiryYear`: Card expiry date
  - `isDefault`: Whether this is the user's default payment method
  - `createdAt` & `lastUsedAt`: Timestamps for tracking

### 2. Service Layer (`PaymentCardService`)

- **Location**: `lib/features/payments/services/payment_card_service.dart`
- **Key Methods**:
  - `savePaymentCard()`: Add new card to Firestore
  - `getUserPaymentCards()`: Get all cards for a user
  - `setCardAsDefault()`: Set a card as the default payment method
  - `deletePaymentCard()`: Remove a card with proper cleanup
  - `cardExists()`: Check for duplicate cards
  - Card type auto-detection from card number

### 3. State Management (`PaymentCardViewModel`)

- **Location**: `lib/features/payments/viewmodels/payment_card_viewmodel.dart`
- **Features**:
  - Extends `ChangeNotifier` for Provider integration
  - Manages loading states and error handling
  - Provides validation methods for card data
  - Integrates with Firebase Auth for user context

### 4. User Interface

#### Card List Screen (`UserCardsScreen`)

- **Location**: `lib/features/payments/screens/user_cards_screen.dart`
- **Features**:
  - Beautiful card display with gradients based on card type
  - Shows card status (Default, Expired, Expires Soon)
  - Popup menu for card actions (Set Default, Delete)
  - Empty state with call-to-action
  - Floating action button to add new cards
  - Pull-to-refresh functionality

#### Add Card Form (`AddCardScreen`)

- **Location**: `lib/features/payments/screens/add_card_screen.dart`
- **Features**:
  - Live card preview that updates as you type
  - Card type auto-detection and display
  - Input formatters for card number (adds spaces automatically)
  - Comprehensive form validation
  - Expiry date validation (prevents past dates)
  - Option to set as default payment method
  - Educational disclaimer

#### Demo Screen (`PaymentCardDemo`)

- **Location**: `lib/features/payments/screens/payment_card_demo.dart`
- **Features**:
  - Test card examples for demonstration
  - Quick action to add sample cards
  - Card statistics display
  - Feature showcase
  - Educational disclaimers

## Firestore Structure

Cards are stored in the `payment_cards` collection with the following structure:

```
payment_cards/{cardId}
├── userId: string
├── cardHolderName: string
├── lastFourDigits: string
├── cardType: string
├── expiryMonth: string
├── expiryYear: string
├── isDefault: boolean
├── createdAt: timestamp
└── lastUsedAt: timestamp (optional)
```

## Security Rules

Security rules are provided in `firestore_security_rules_cards.rules`:

```javascript
// Users can only access their own cards
match /payment_cards/{cardId} {
  allow read, write: if request.auth != null
    && request.auth.uid == resource.data.userId;
  allow create: if request.auth != null
    && request.auth.uid == request.resource.data.userId;
}
```

## Integration with Main App

### 1. Provider Setup

The `PaymentCardViewModel` is registered in `main.dart`:

```dart
MultiProvider(
  providers: [
    // ... other providers
    ChangeNotifierProvider(create: (_) => PaymentCardViewModel()),
  ],
  child: MyApp(),
)
```

### 2. Navigation Integration

Cards screen is accessible from the profile tab:

```dart
// In profile_tab.dart
_MenuOption(
  icon: Icons.credit_card_outlined,
  title: 'My Cards',
  subtitle: 'Manage saved payment cards',
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserCardsScreen(),
      ),
    );
  },
),
```

## Test Data

For demonstration purposes, use these test card numbers:

### Visa Test Cards

- **Number**: `4242 4242 4242 4242`
- **Expiry**: `12/28`
- **CVV**: `123`

### Mastercard Test Cards

- **Number**: `5555 5555 5555 4444`
- **Expiry**: `10/27`
- **CVV**: `456`

### American Express Test Cards

- **Number**: `3782 822463 10005`
- **Expiry**: `09/26`
- **CVV**: `7890`

## Usage Examples

### Adding a Card

```dart
final cardViewModel = Provider.of<PaymentCardViewModel>(context, listen: false);

final success = await cardViewModel.addCard(
  cardNumber: '4242424242424242',
  cardHolderName: 'John Doe',
  expiryMonth: '12',
  expiryYear: '28',
  cvv: '123',
  setAsDefault: true,
);
```

### Loading User Cards

```dart
// In widget
Consumer<PaymentCardViewModel>(
  builder: (context, cardViewModel, child) {
    if (cardViewModel.isLoading) {
      return CircularProgressIndicator();
    }

    return ListView.builder(
      itemCount: cardViewModel.cards.length,
      itemBuilder: (context, index) {
        final card = cardViewModel.cards[index];
        return CardTile(card: card);
      },
    );
  },
)
```

### Setting Default Card

```dart
await cardViewModel.setCardAsDefault(cardId);
```

### Deleting a Card

```dart
await cardViewModel.deleteCard(cardId);
```

## Validation Features

1. **Card Number Validation**: Checks length and format
2. **Expiry Date Validation**: Prevents past dates
3. **Duplicate Detection**: Prevents adding the same card twice
4. **Required Field Validation**: All fields must be filled
5. **CVV Validation**: Appropriate length based on card type

## Error Handling

- Network errors are caught and displayed to users
- Validation errors are shown inline
- Loading states prevent multiple submissions
- User-friendly error messages
- Automatic retry mechanisms

## Future Enhancements

- Card scanning using camera
- Support for more card types
- Card verification codes
- Payment history integration
- Card usage analytics
- Batch operations
- Import/export functionality

## Files Modified/Created

### New Files

- `lib/features/payments/models/payment_card_model.dart`
- `lib/features/payments/services/payment_card_service.dart`
- `lib/features/payments/viewmodels/payment_card_viewmodel.dart`
- `lib/features/payments/screens/add_card_screen.dart`
- `lib/features/payments/screens/payment_card_demo.dart`
- `firestore_security_rules_cards.rules`

### Modified Files

- `lib/main.dart` - Added PaymentCardViewModel to providers
- `lib/features/payments/screens/user_cards_screen.dart` - Updated to use Provider
- `lib/features/dashboards/customer/screens/profile_tab.dart` - Added navigation

## Testing the Implementation

1. **Run the Demo**: Navigate to the PaymentCardDemo screen to see all features
2. **Add Sample Cards**: Use the "Add All Sample Cards" button for quick testing
3. **Test Card Operations**: Add, edit, delete, and set default cards
4. **Test Validation**: Try invalid inputs to see validation in action
5. **Test Error Handling**: Disconnect internet to test error states

## Educational Disclaimers

- This implementation is for educational purposes only
- No real payment processing occurs
- No sensitive financial data should be used
- Always follow PCI compliance in real applications
- This is a simulation suitable for Final Year Projects

## Conclusion

This implementation provides a complete, production-ready pattern for card management in Flutter applications while maintaining security best practices and providing an excellent user experience. It demonstrates proper separation of concerns, state management, error handling, and UI/UX design principles.
