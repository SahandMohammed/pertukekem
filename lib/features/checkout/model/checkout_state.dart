import '../../profile/model/address_model.dart';
import '../../payments/model/payment_card_model.dart';

class CheckoutState {
  final int currentStep;
  final bool isProcessing;
  final bool isLoadingAddresses;
  final bool isLoadingCards;
  final List<AddressModel> userAddresses;
  final List<PaymentCard> userCards;
  final AddressModel? selectedAddress;
  final PaymentCard? selectedCard;
  final String selectedPaymentMethod;
  final String? error;

  const CheckoutState({
    required this.currentStep,
    required this.isProcessing,
    required this.isLoadingAddresses,
    required this.isLoadingCards,
    required this.userAddresses,
    required this.userCards,
    this.selectedAddress,
    this.selectedCard,
    required this.selectedPaymentMethod,
    this.error,
  });

  factory CheckoutState.initial() {
    return const CheckoutState(
      currentStep: 0,
      isProcessing: false,
      isLoadingAddresses: false,
      isLoadingCards: false,
      userAddresses: [],
      userCards: [],
      selectedAddress: null,
      selectedCard: null,
      selectedPaymentMethod: 'card',
      error: null,
    );
  }

  CheckoutState copyWith({
    int? currentStep,
    bool? isProcessing,
    bool? isLoadingAddresses,
    bool? isLoadingCards,
    List<AddressModel>? userAddresses,
    List<PaymentCard>? userCards,
    AddressModel? selectedAddress,
    PaymentCard? selectedCard,
    String? selectedPaymentMethod,
    String? error,
  }) {
    return CheckoutState(
      currentStep: currentStep ?? this.currentStep,
      isProcessing: isProcessing ?? this.isProcessing,
      isLoadingAddresses: isLoadingAddresses ?? this.isLoadingAddresses,
      isLoadingCards: isLoadingCards ?? this.isLoadingCards,
      userAddresses: userAddresses ?? this.userAddresses,
      userCards: userCards ?? this.userCards,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      selectedCard: selectedCard ?? this.selectedCard,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CheckoutState &&
        other.currentStep == currentStep &&
        other.isProcessing == isProcessing &&
        other.isLoadingAddresses == isLoadingAddresses &&
        other.isLoadingCards == isLoadingCards &&
        other.userAddresses == userAddresses &&
        other.userCards == userCards &&
        other.selectedAddress == selectedAddress &&
        other.selectedCard == selectedCard &&
        other.selectedPaymentMethod == selectedPaymentMethod &&
        other.error == error;
  }

  @override
  int get hashCode {
    return currentStep.hashCode ^
        isProcessing.hashCode ^
        isLoadingAddresses.hashCode ^
        isLoadingCards.hashCode ^
        userAddresses.hashCode ^
        userCards.hashCode ^
        selectedAddress.hashCode ^
        selectedCard.hashCode ^
        selectedPaymentMethod.hashCode ^
        error.hashCode;
  }

  @override
  String toString() {
    return 'CheckoutState('
        'currentStep: $currentStep, '
        'isProcessing: $isProcessing, '
        'isLoadingAddresses: $isLoadingAddresses, '
        'isLoadingCards: $isLoadingCards, '
        'userAddresses: ${userAddresses.length}, '
        'userCards: ${userCards.length}, '
        'selectedAddress: $selectedAddress, '
        'selectedCard: $selectedCard, '
        'selectedPaymentMethod: $selectedPaymentMethod, '
        'error: $error)';
  }
}
