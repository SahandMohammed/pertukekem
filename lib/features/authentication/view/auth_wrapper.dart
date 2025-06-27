import 'package:flutter/material.dart';
import 'package:pertukekem/features/dashboards/view/customer/customer_dashboard.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../admin/view/admin_dashboard_screen.dart';
import '../../dashboards/view/store/store_dashboard.dart';
import '../../profile/view/store/store_setup_screen.dart';
import 'login_screen.dart';
import 'blocked_user_screen.dart';
import 'verify_email_screen.dart';
import 'phone_verification_flow_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        if (authViewModel.firebaseUser == null) {
          return const LoginScreen();
        }

        if (authViewModel.isLoading || authViewModel.user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authViewModel.user!.isEmailVerified) {
          return const VerifyEmailScreen();
        }

        if (!authViewModel.isPhoneVerified) {
          return const PhoneVerificationFlowScreen();
        }

        if (authViewModel.user!.isBlocked) {
          return const BlockedUserScreen();
        }

        if (authViewModel.user!.roles.contains('admin')) {
          return const AdminDashboardScreen();
        } else if (authViewModel.user!.roles.contains('store')) {
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
