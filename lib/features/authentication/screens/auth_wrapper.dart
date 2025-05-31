import 'package:flutter/material.dart';
import 'package:pertukekem/features/dashboards/customer/screens/customer_dashboard.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'admin_dashboard.dart';
import '../../dashboards/store/screens/store_dashboard.dart';
import '../../dashboards/store/screens/store_setup_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        // Show login screen if no user is authenticated
        if (authViewModel.firebaseUser == null) {
          return const LoginScreen();
        }

        // Show loading while fetching user data
        if (authViewModel.isLoading || authViewModel.user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user exists but phone isn't verified, clean up and show login
        if (!authViewModel.isPhoneVerified) {
          // Note: cleanup is handled in AuthViewModel.handleUnverifiedUser
          return const LoginScreen();
        } // Only show dashboard if user is fully verified
        // Check user role and redirect accordingly
        if (authViewModel.user!.roles.contains('admin')) {
          return const AdminDashboard();
        } else if (authViewModel.user!.roles.contains('store')) {
          // Check if the store user needs to complete setup
          final storeId = authViewModel.user!.storeId;
          if (storeId == null || storeId.isEmpty) {
            return const StoreSetupScreen();
          }
          return const StoreDashboard();
        } else {
          return const CustomerDashboard();
        }
      },
    );
  }
}
