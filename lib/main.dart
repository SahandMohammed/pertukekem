import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pertukekem/core/services/firebase_options.dart';
import 'package:pertukekem/core/services/fcm_service.dart';
import 'package:pertukekem/core/theme/app_theme.dart';
import 'package:pertukekem/features/AI/service/ai_service.dart';
import 'package:pertukekem/features/checkout/viewmodel/checkout_viewmodel.dart';
import 'package:pertukekem/features/dashboards/viewmodel/customer_home_viewmodel.dart';
import 'package:pertukekem/features/orders/viewmodel/customer_orders_viewmodel.dart';
import 'package:pertukekem/features/library/viewmodel/library_viewmodel.dart';
import 'package:pertukekem/features/listings/viewmodel/manage_listings_viewmodel.dart';
import 'package:pertukekem/features/orders/viewmodel/store_order_viewmodel.dart';
import 'package:pertukekem/features/profile/viewmodel/store_profile_viewmodel.dart';
import 'package:pertukekem/features/profile/viewmodel/user_profile_viewmodel.dart';
import 'package:pertukekem/features/payments/viewmodel/payment_card_viewmodel.dart';
import 'package:pertukekem/features/admin/viewmodel/admin_viewmodel.dart';
import 'package:pertukekem/features/book_requests/viewmodel/book_request_viewmodel.dart';
import 'package:provider/provider.dart';
import 'features/authentication/viewmodel/auth_viewmodel.dart';
import 'features/authentication/view/auth_wrapper.dart';
import 'features/profile/viewmodel/store_setup_viewmodel.dart';
import 'features/cart/services/cart_service.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await FCMService().initialize();

  await AIService.instance.initialize(useVertexBackend: false);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => StoreSetupViewmodel()),
        ChangeNotifierProvider(create: (_) => ManageListingsViewModel()),
        ChangeNotifierProvider(create: (_) => CustomerHomeViewModel()),
        ChangeNotifierProvider(create: (_) => CustomerOrdersViewModel()),
        ChangeNotifierProvider(create: (_) => LibraryViewModel()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => UserProfileViewModel()),
        ChangeNotifierProvider(create: (_) => PaymentCardViewModel()),
        ChangeNotifierProvider(create: (_) => StoreOrderViewModel()),
        ChangeNotifierProvider(create: (_) => CheckoutViewModel()),
        ChangeNotifierProvider(create: (_) => AdminViewModel()),
        ChangeNotifierProvider(create: (_) => BookRequestViewModel()),
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _registerStateClearables(context, authViewModel);
          });

          return const MyApp();
        },
      ),
    ),
  );
}

void _registerStateClearables(
  BuildContext context,
  AuthViewModel authViewModel,
) {
  final storeViewModel = context.read<StoreSetupViewmodel>();
  final manageListingsViewModel = context.read<ManageListingsViewModel>();
  final customerHomeViewModel = context.read<CustomerHomeViewModel>();
  final customerOrdersViewModel = context.read<CustomerOrdersViewModel>();
  final libraryViewModel = context.read<LibraryViewModel>();
  final cartService = context.read<CartService>();
  final profileViewModel = context.read<ProfileViewModel>();
  final paymentCardViewModel = context.read<PaymentCardViewModel>();
  final storeOrderViewModel = context.read<StoreOrderViewModel>();
  final checkoutViewModel = context.read<CheckoutViewModel>();
  final adminViewModel = context.read<AdminViewModel>();
  final bookRequestViewModel = context.read<BookRequestViewModel>();

  authViewModel.registerStateClearable(storeViewModel.clearState);
  authViewModel.registerStateClearable(manageListingsViewModel.clearState);
  authViewModel.registerStateClearable(customerHomeViewModel.clearState);
  authViewModel.registerStateClearable(customerOrdersViewModel.clearState);
  authViewModel.registerStateClearable(libraryViewModel.clearState);
  authViewModel.registerStateClearable(cartService.clearState);
  authViewModel.registerStateClearable(profileViewModel.clearState);
  authViewModel.registerStateClearable(paymentCardViewModel.clearState);
  authViewModel.registerStateClearable(storeOrderViewModel.clearState);
  authViewModel.registerStateClearable(checkoutViewModel.clearState);
  authViewModel.registerStateClearable(adminViewModel.clearState);
  authViewModel.registerStateClearable(bookRequestViewModel.clearState);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pertukekem',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AuthWrapper(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
