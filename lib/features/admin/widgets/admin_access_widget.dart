import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/viewmodel/auth_viewmodel.dart';

class AdminAccessWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AdminAccessWidget({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        final user = authViewModel.user;

        if (user == null || !user.isAdmin) {
          return fallback ??
              Scaffold(
                appBar: AppBar(title: const Text('Access Denied')),
                body: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Admin Access Required',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You don\'t have permission to access this area.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
        }

        return child;
      },
    );
  }
}
