import 'package:flutter/foundation.dart';
import 'package:pertukekem/core/interfaces/state_clearable.dart';
import '../service/ai_service.dart';
import '../model/chat_message_model.dart';

/// ViewModel for managing AI chat functionality
class AIChatViewModel extends ChangeNotifier implements StateClearable {
  final AIService _aiService = AIService.instance;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMessages => _messages.isNotEmpty;

  /// Initialize the AI chat session
  Future<void> initializeChatSession() async {
    try {
      await _aiService.initialize();
      _aiService.startBookstoreFocusedChat();
      _addWelcomeMessage();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize chat session: $e';
      notifyListeners();
    }
  }

  /// Add welcome message when chat starts
  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content:
          '''Hello! I'm your AI reading assistant for Pertukekem Bookstore! 📚

I'm here to help you with:
• Book recommendations based on your preferences
• Information about books and authors
• Reading suggestions and literary discussions
• Bookstore navigation and features
• Digital library management

What would you like to explore today?''',
      isUser: false,
      timestamp: DateTime.now(),
    );

    _messages.add(welcomeMessage);
  }

  /// Send a message to the AI and get response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    _error = null;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);

    // Add loading message
    final loadingMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_loading',
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    _messages.add(loadingMessage);
    _isLoading = true;
    notifyListeners();

    try {
      // Get AI response
      final response = await _aiService.generateBookstoreContent(content);

      // Remove loading message
      _messages.removeWhere((msg) => msg.id.endsWith('_loading'));

      // Add AI response
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _messages.add(aiMessage);
    } catch (e) {
      // Remove loading message
      _messages.removeWhere((msg) => msg.id.endsWith('_loading'));

      _error = 'Failed to get response: $e';

      // Add error message
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I encountered an error. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      _messages.add(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all messages and end chat session
  void clearChat() {
    _messages.clear();
    _error = null;
    _isLoading = false;
    _aiService.endCurrentChatSession();
    notifyListeners();
  }

  /// Start a new chat session
  void startNewChat() {
    clearChat();
    _aiService.startBookstoreFocusedChat();
    _addWelcomeMessage();
    notifyListeners();
  }

  /// Get quick suggestion prompts
  List<String> getQuickSuggestions() {
    return [
      'Recommend some fantasy books',
      'What are trending books this month?',
      'Books similar to Harry Potter',
      'Best romance novels',
      'Classic literature recommendations',
      'Science fiction for beginners',
    ];
  }

  @override
  void dispose() {
    _aiService.endCurrentChatSession();
    super.dispose();
  }

  @override
  Future<void> clearState() async {
    clearChat();
  }
}
