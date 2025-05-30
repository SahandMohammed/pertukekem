import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pertukekem/core/services/firebase_options.dart';
import 'package:pertukekem/core/theme/app_theme.dart';
import 'package:pertukekem/features/listings/viewmodel/manage_listings_viewmodel.dart';
import 'package:pertukekem/features/orders/viewmodel/order_viewmodel.dart';
import 'package:provider/provider.dart';
import 'features/authentication/viewmodels/auth_viewmodel.dart';
import 'features/authentication/screens/auth_wrapper.dart';
import 'features/dashboards/store/viewmodels/store_viewmodel.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => StoreViewModel()),
        ChangeNotifierProvider(create: (_) => ManageListingsViewModel()),
        ChangeNotifierProvider(create: (_) => OrderViewModel()),
      ],
      child: const MyApp(),
    ),
  );
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
