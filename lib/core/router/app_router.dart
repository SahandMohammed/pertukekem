import 'package:flutter/material.dart';
import 'package:pertukekem/features/cart/view/cart_screen.dart';
import '../../features/authentication/view/verify_phone_screen.dart';
import '../../features/authentication/view/auth_wrapper.dart';
import '../../features/profile/view/store/store_setup_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
      case '/verify-phone':
        final verificationId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => VerifyPhoneScreen(verificationId: verificationId),
        );
      case '/store-setup':
        return MaterialPageRoute(builder: (_) => const StoreSetupScreen());
      case '/cart':
        return MaterialPageRoute(builder: (_) => const CartScreen());
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
