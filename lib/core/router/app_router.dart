import 'package:flutter/material.dart';
import 'package:pertukekem/features/cart/screens/cart_screen.dart';
import '../../features/authentication/screens/verify_phone_screen.dart';
import '../../features/authentication/screens/auth_wrapper.dart';
import '../../features/dashboards/store/screens/store_setup_screen.dart';
import '../test/notification_test_screen.dart';

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
      case '/notification-test':
        return MaterialPageRoute(
          builder: (_) => const NotificationTestScreen(),
        );
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
