import 'package:flutter/material.dart';
import '../widgets/common_app_bar.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Admin Dashboard'),
      body: const Center(child: Text('Admin Dashboard')),
    );
  }
}
