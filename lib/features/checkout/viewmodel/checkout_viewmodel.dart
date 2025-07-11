import 'package:flutter/foundation.dart';
import 'package:pertukekem/core/interfaces/state_clearable.dart';
import '../../authentication/viewmodel/auth_viewmodel.dart';
import '../../cart/model/cart_item_model.dart';
import '../../cart/services/cart_service.dart';
import '../../profile/model/address_model.dart';
import '../../profile/viewmodel/store_profile_viewmodel.dart';
import '../../payments/model/payment_card_model.dart';
import '../../payments/viewmodel/payment_card_viewmodel.dart';
import '../service/checkout_service.dart';
import '../model/checkout_state.dart';

class CheckoutViewModel extends ChangeNotifier implements StateClearable {
  final CheckoutService _checkoutService = CheckoutService();

  CheckoutState _state = CheckoutState.initial();
  CheckoutState get state => _state;

  int get currentStep => _state.currentStep;
  bool get isProcessing => _state.isProcessing;
  bool get isLoadingAddresses => _state.isLoadingAddresses;
  bool get isLoadingCards => _state.isLoadingCards;

  List<AddressModel> get userAddresses => _state.userAddresses;
  List<PaymentCard> get userCards => _state.userCards;
  AddressModel? get selectedAddress => _state.selectedAddress;
  PaymentCard? get selectedCard => _state.selectedCard;
  String get selectedPaymentMethod => _state.selectedPaymentMethod;

  late AuthViewModel _authViewModel;
  late ProfileViewModel _profileViewModel;
  late PaymentCardViewModel _paymentCardViewModel;
  late CartService _cartService;

  void setDependencies({
    required AuthViewModel authViewModel,
    required ProfileViewModel profileViewModel,
    required PaymentCardViewModel paymentCardViewModel,
    required CartService cartService,
  }) {
    _authViewModel = authViewModel;
    _profileViewModel = profileViewModel;
    _paymentCardViewModel = paymentCardViewModel;
    _cartService = cartService;
  }

  void setCurrentStep(int step) {
    _state = _state.copyWith(currentStep: step);
    notifyListeners();
  }

  void nextStep() {
    if (_state.currentStep < 2) {
      _state = _state.copyWith(currentStep: _state.currentStep + 1);
      notifyListeners();
    }
  }

  void previousStep() {
    if (_state.currentStep > 0) {
      _state = _state.copyWith(currentStep: _state.currentStep - 1);
      notifyListeners();
    }
  }

  void selectAddress(AddressModel address) {
    _state = _state.copyWith(selectedAddress: address);
    notifyListeners();
  }

  void selectCard(PaymentCard card) {
    _state = _state.copyWith(selectedCard: card);
    notifyListeners();
  }

  void selectPaymentMethod(String method) {
    _state = _state.copyWith(selectedPaymentMethod: method);
    if (method == 'cod') {
      _state = _state.copyWith(selectedCard: null);
    }
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    await Future.wait([loadUserAddresses(), loadUserCards()]);
  }

  Future<void> loadUserAddresses() async {
    final user = _authViewModel.user;
    if (user == null) {
      debugPrint('CheckoutViewModel: Cannot load addresses - user is null');
      return;
    }

    debugPrint('CheckoutViewModel: Loading addresses for user ${user.userId}');
    _state = _state.copyWith(isLoadingAddresses: true);
    notifyListeners();

    try {
      _profileViewModel.setAuthViewModel(_authViewModel);
      await _profileViewModel.loadAddresses(user);

      final addresses = _profileViewModel.addresses;
      debugPrint(
        'CheckoutViewModel: Loaded ${addresses.length} addresses from ProfileViewModel',
      );

      final selectedAddress =
          addresses.isNotEmpty
              ? addresses.firstWhere(
                (addr) => addr.isDefault,
                orElse: () => addresses.first,
              )
              : null;

      if (selectedAddress != null) {
        debugPrint(
          'CheckoutViewModel: Selected default address: ${selectedAddress.id}',
        );
      } else {
        debugPrint('CheckoutViewModel: No addresses available for selection');
      }

      _state = _state.copyWith(
        userAddresses: addresses,
        selectedAddress: selectedAddress,
      );
    } catch (e) {
      debugPrint('CheckoutViewModel: Error loading addresses: $e');
      _state = _state.copyWith(error: 'Failed to load addresses: $e');
    } finally {
      _state = _state.copyWith(isLoadingAddresses: false);
      notifyListeners();
    }
  }

  Future<void> loadUserCards() async {
    _state = _state.copyWith(isLoadingCards: true);
    notifyListeners();

    try {
      await _paymentCardViewModel.loadCards();

      final cards = _paymentCardViewModel.cards;
      final selectedCard =
          cards.isNotEmpty
              ? cards.firstWhere(
                (card) => card.isDefault,
                orElse: () => cards.first,
              )
              : null;

      _state = _state.copyWith(userCards: cards, selectedCard: selectedCard);
    } catch (e) {
      debugPrint('Error loading cards: $e');
      _state = _state.copyWith(error: 'Failed to load payment cards: $e');
    } finally {
      _state = _state.copyWith(isLoadingCards: false);
      notifyListeners();
    }
  }

  bool canProceedToNextStep() {
    switch (_state.currentStep) {
      case 0:
        return true; // Always can proceed from order review
      case 1:
        return _state.selectedAddress != null;
      default:
        return false;
    }
  }

  bool canPlaceOrder() {
    return _state.selectedAddress != null &&
        (_state.selectedPaymentMethod == 'cod' ||
            (_state.selectedPaymentMethod == 'card' &&
                _state.selectedCard != null));
  }

  Future<List<dynamic>> processOrder(Cart cart) async {
    final user = _authViewModel.user;
    if (user == null) {
      throw Exception('Please log in to continue');
    }

    _state = _state.copyWith(isProcessing: true);
    notifyListeners();

    try {
      final shippingAddress = _state.selectedAddress!.fullAddress;

      Map<String, String>? cardInfo;
      if (_state.selectedPaymentMethod == 'card' &&
          _state.selectedCard != null) {
        final card = _state.selectedCard!;
        cardInfo = {
          'cardId': card.id,
          'cardType': card.cardType,
          'lastFourDigits': card.lastFourDigits,
          'cardholderName': card.cardHolderName,
          'expiry': '${card.expiryMonth}/${card.expiryYear}',
        };
      }

      final results = await _checkoutService.processCartCheckout(
        cart: cart,
        buyerId: user.userId,
        paymentMethod: _state.selectedPaymentMethod,
        shippingAddress: shippingAddress,
        customerInfo: {
          'name': '${user.firstName} ${user.lastName}',
          'email': user.email,
          'phone': user.phoneNumber,
          'addressId': _state.selectedAddress!.id,
          'selectedCardId': _state.selectedCard?.id ?? '',
        },
        cardInfo: cardInfo,
      );

      await _cartService.clearCart();

      await clearState();

      return results;
    } catch (e) {
      _state = _state.copyWith(error: 'Order failed: ${e.toString()}');
      notifyListeners();
      rethrow;
    } finally {
      _state = _state.copyWith(isProcessing: false);
      notifyListeners();
    }
  }

  Future<void> refreshAddresses() async {
    debugPrint('CheckoutViewModel: Refreshing addresses...');

    // First, refresh the user data from the database to get the latest addresses
    try {
      await _authViewModel.refreshUserData();
      debugPrint('CheckoutViewModel: User data refreshed from database');
    } catch (e) {
      debugPrint('CheckoutViewModel: Error refreshing user data: $e');
    }

    // Then reload addresses using the refreshed user data
    await loadUserAddresses();
  }

  Future<void> refreshCards() async {
    await loadUserCards();
  }

  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }

  void resetToInitialState() {
    debugPrint('CheckoutViewModel: Resetting to initial state');
    _state = CheckoutState.initial();
    notifyListeners();
  }

  @override
  Future<void> clearState() async {
    _state = CheckoutState.initial();
    notifyListeners();
  }
}
