import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service class to manage Firebase AI functionality
/// Provides access to both Google AI and Vertex AI backends
class AIService {
  static AIService? _instance;
  late GenerativeModel _currentModel;
  late ImagenModel _currentImagenModel;
  bool _useVertexBackend = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Private constructor
  AIService._();

  /// Singleton instance of AIService
  static AIService get instance {
    _instance ??= AIService._();
    return _instance!;
  }

  /// Initialize the AI service with default settings
  Future<void> initialize({bool useVertexBackend = false}) async {
    _useVertexBackend = useVertexBackend;
    await _initializeModel(_useVertexBackend);
  }

  /// Initialize the generative model based on backend choice
  Future<void> _initializeModel(bool useVertexBackend) async {
    try {
      if (useVertexBackend) {
        final vertexInstance = FirebaseAI.vertexAI(auth: _auth);
        _currentModel = vertexInstance.generativeModel(
          model: 'gemini-1.5-flash',
        );
        _currentImagenModel = _initializeImagenModel(vertexInstance);
      } else {
        final googleAI = FirebaseAI.googleAI(auth: _auth);
        _currentModel = googleAI.generativeModel(model: 'gemini-2.0-flash');
        _currentImagenModel = _initializeImagenModel(googleAI);
      }
      debugPrint(
        'AI Service initialized with ${useVertexBackend ? 'Vertex AI' : 'Google AI'}',
      );
    } catch (e) {
      debugPrint('Error initializing AI Service: $e');
      rethrow;
    }
  }

  /// Initialize Imagen model for image generation
  ImagenModel _initializeImagenModel(FirebaseAI instance) {
    var generationConfig = ImagenGenerationConfig(
      numberOfImages: 1,
      aspectRatio: ImagenAspectRatio.square1x1,
      imageFormat: ImagenFormat.jpeg(compressionQuality: 75),
    );
    return instance.imagenModel(
      model: 'imagen-3.0-generate-002',
      generationConfig: generationConfig,
      safetySettings: ImagenSafetySettings(
        ImagenSafetyFilterLevel.blockLowAndAbove,
        ImagenPersonFilterLevel.allowAdult,
      ),
    );
  }

  /// Switch between Google AI and Vertex AI backends
  Future<void> toggleBackend() async {
    _useVertexBackend = !_useVertexBackend;
    await _initializeModel(_useVertexBackend);
  }

  /// Set specific backend
  Future<void> setBackend(bool useVertexBackend) async {
    if (_useVertexBackend != useVertexBackend) {
      _useVertexBackend = useVertexBackend;
      await _initializeModel(_useVertexBackend);
    }
  }

  /// Generate text content from prompt
  Future<String> generateContent(String prompt) async {
    try {
      final response = await _currentModel.generateContent([
        Content.text(prompt),
      ]);
      return response.text ?? 'No response generated';
    } catch (e) {
      debugPrint('Error generating content: $e');
      throw Exception('Failed to generate content: $e');
    }
  }

  /// Generate streaming text content from prompt
  Stream<String> generateStreamingContent(String prompt) async* {
    try {
      final stream = _currentModel.generateContentStream([
        Content.text(prompt),
      ]);
      await for (final chunk in stream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      debugPrint('Error generating streaming content: $e');
      throw Exception('Failed to generate streaming content: $e');
    }
  }

  /// Count tokens in a prompt
  Future<int> countTokens(String prompt) async {
    try {
      final response = await _currentModel.countTokens([Content.text(prompt)]);
      return response.totalTokens;
    } catch (e) {
      debugPrint('Error counting tokens: $e');
      throw Exception('Failed to count tokens: $e');
    }
  }

  /// Start multi-turn chat conversations
  ChatSession startChat({List<Content>? history}) {
    return _currentModel.startChat(history: history);
  }

  // Chat session management
  ChatSession? _currentChatSession;

  /// Start a chat conversation with predefined bookstore-focused system context
  ChatSession startBookstoreFocusedChat() {
    // Create system context for bookstore conversations
    final systemContext = Content.text('''
You are a specialized AI assistant for an online bookstore called Pertukekem. Your role is to help users with:

ALLOWED TOPICS:
- Book recommendations based on genres, authors, or preferences
- Book information, summaries, and reviews
- Reading suggestions and reading lists
- Author information and biographies
- Book genres and categories
- Literary discussions and analysis
- Reading tips and habits
- Bookstore navigation and features
- Order and purchase guidance
- Digital library management
- Reading progress and goals

RESPONSE STYLE:
- Be enthusiastic about books and reading
- Provide personalized recommendations when possible
- Use simple, clear language
- Be helpful and engaging
- Keep responses conversational and friendly
- If asked about non-book topics, politely redirect to bookstore-related questions

RESTRICTIONS:
- Do NOT provide information unrelated to books, reading, or the bookstore
- Do NOT give medical, legal, or financial advice
- Stay focused on literature and bookstore services

Remember: You are a book-loving assistant here to enhance the reading experience.
- IMPORTANT: Use raw text and do not decorate the response with markdown or formatting.
''');

    _currentChatSession = _currentModel.startChat(history: [systemContext]);
    return _currentChatSession!;
  }

  /// Get current active chat session or create new one
  ChatSession getCurrentChatSession() {
    _currentChatSession ??= startBookstoreFocusedChat();
    return _currentChatSession!;
  }

  /// End current chat session and clear cache
  void endCurrentChatSession() {
    _currentChatSession = null;
    debugPrint('Chat session ended and cache cleared');
  }

  /// Check if there's an active chat session
  bool get hasActiveChatSession => _currentChatSession != null;

  /// Generate bookstore-related content with context
  Future<String> generateBookstoreContent(String prompt) async {
    try {
      // Use the current chat session to maintain context
      final chatSession = getCurrentChatSession();
      final response = await chatSession.sendMessage(Content.text(prompt));
      return response.text ?? 'No response generated';
    } catch (e) {
      debugPrint('Error generating bookstore content: $e');
      throw Exception('Failed to generate bookstore content: $e');
    }
  }

  /// Get book recommendations based on user preferences
  Future<String> getBookRecommendations(String preferences) async {
    try {
      final prompt = '''
Based on these preferences: $preferences

Please provide personalized book recommendations including:
1. Specific book titles and authors
2. Brief descriptions of why these books match the preferences
3. Different genres that might interest the reader
4. Both popular and hidden gem suggestions

Please make the recommendations engaging and personalized.
''';

      return await generateBookstoreContent(prompt);
    } catch (e) {
      debugPrint('Error getting book recommendations: $e');
      throw Exception('Failed to get book recommendations: $e');
    }
  }

  /// Get information about a specific book or author
  Future<String> getBookInformation(String query) async {
    try {
      final prompt = '''
Please provide information about: $query

Include relevant details such as:
- Summary or plot overview (if it's a book)
- Author background and other works
- Genre and themes
- Reading level or target audience
- Similar books or authors
- Why readers might enjoy this

Keep the information engaging and helpful for someone interested in reading.
''';

      return await generateBookstoreContent(prompt);
    } catch (e) {
      debugPrint('Error getting book information: $e');
      throw Exception('Failed to get book information: $e');
    }
  }

  // Getters
  GenerativeModel get currentModel => _currentModel;
  ImagenModel get currentImagenModel => _currentImagenModel;
  bool get isUsingVertexBackend => _useVertexBackend;
  String get currentBackendName =>
      _useVertexBackend ? 'Vertex AI' : 'Google AI';
  bool get isUserAuthenticated => _auth.currentUser != null;
  String? get currentUserId => _auth.currentUser?.uid;
}
