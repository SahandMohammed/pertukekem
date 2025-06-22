import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/ai_chat_viewmodel.dart';
import 'ai_chat_screen.dart';

/// Tab wrapper for AI Chat in the customer dashboard
class AIChatTab extends StatelessWidget {
  const AIChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AIChatViewModel(),
      child: const AIChatScreen(),
    );
  }
}
