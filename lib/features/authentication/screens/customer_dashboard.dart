import 'package:flutter/material.dart';
import '../widgets/common_app_bar.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Customer Dashboard'),
      body: const Center(child: Text('Customer Dashboard')),
    );
  }
}
