import 'package:flutter/material.dart';
import 'package:pertukekem/features/dashboards/view/customer/customer_dashboard.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../admin/view/admin_dashboard_screen.dart';
import '../../dashboards/view/store/store_dashboard.dart';
import '../../profile/view/store/store_setup_screen.dart';
import 'login_screen.dart';
import 'blocked_user_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        // Show login screen if no user is authenticated
        if (authViewModel.firebaseUser == null) {
          return LoginScreen();
        }

        // Show loading while fetching user data
        if (authViewModel.isLoading || authViewModel.user == null) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } // If user exists but phone isn't verified, clean up and show login
        if (!authViewModel.isPhoneVerified) {
          // Note: cleanup is handled in AuthViewModel.handleUnverifiedUser
          return LoginScreen();
        }

        // Check if user is blocked
        if (authViewModel.user!.isBlocked) {
          return BlockedUserScreen();
        }

        // Only show dashboard if user is fully verified// Check user role and redirect accordingly
        if (authViewModel.user!.roles.contains('admin')) {
          return AdminDashboardScreen();
        } else if (authViewModel.user!.roles.contains('store')) {
          // Check if the store user needs to complete setup
          final storeId = authViewModel.user!.storeId;
          if (storeId == null || storeId.isEmpty) {
            return StoreSetupScreen();
          }
          return StoreDashboard();
        } else {
          return CustomerDashboard();
        }
      },
    );
  }
}
