import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/viewmodel/auth_viewmodel.dart';

class AdminFloatingButton extends StatelessWidget {
  const AdminFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final user = authViewModel.user;

        // Only show admin button for admin users
        if (user == null || !user.isAdmin) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          heroTag: "admin_panel_fab",
          onPressed: () {
            Navigator.pushNamed(context, '/admin');
          },
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.admin_panel_settings),
          label: const Text('Admin'),
        );
      },
    );
  }
}
