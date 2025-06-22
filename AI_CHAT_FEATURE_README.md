# AI Chat Feature Documentation

## Overview

The AI Chat feature provides customers with an intelligent reading assistant powered by Firebase AI. The assistant specializes in book recommendations, literary discussions, and bookstore navigation help.

## Architecture

### Files Structure

```
lib/features/AI/
├── model/
│   └── chat_message_model.dart      # Chat message data model
├── service/
│   └── ai_service.dart              # Firebase AI service integration
├── viewmodel/
│   └── ai_chat_viewmodel.dart       # Chat state management
└── view/
    ├── ai_chat_screen.dart          # Main chat interface
    ├── ai_chat_tab.dart             # Tab wrapper for dashboard
    └── widgets/
        ├── chat_message_bubble.dart # Individual message UI
        └── quick_suggestion_chips.dart # Suggestion chips UI
```

### Key Features

1. **Bookstore-Focused AI**: The AI is specifically trained to help with:

   - Book recommendations based on preferences
   - Author and book information
   - Reading suggestions and literary discussions
   - Bookstore navigation assistance
   - Digital library management

2. **Session Management**:

   - Single session per user until manually ended
   - No persistent chat history storage
   - Session cache cleared when user ends chat

3. **Modern UI Design**:

   - Auto-scrolling chat interface
   - Message bubbles with timestamps
   - Loading indicators during AI responses
   - Quick suggestion chips for common queries
   - Empty state with helpful prompts

4. **Responsive Design**:
   - Adaptive message layout
   - Floating action button for chat management
   - Keyboard-friendly input handling
   - Auto-scroll to latest messages

## Configuration

### AI Service Setup

The AI service uses Firebase AI with Gemini models:

- Default: Google AI with Gemini 2.0 Flash
- Alternative: Vertex AI with Gemini 1.5 Flash
- Image generation: Imagen 3.0 (available but not used in chat)

### Integration Points

- Dashboard navigation tab (4th position)
- Provider pattern for state management
- Material 3 design system compliance

## Usage

### For Users

1. Navigate to "AI Chat" tab in bottom navigation
2. Use quick suggestions or type custom questions
3. Get personalized book recommendations and information
4. Clear chat history using the refresh button or floating action button

### For Developers

1. The AI service is singleton-based for efficient resource usage
2. ViewModel handles all chat state and AI communication
3. UI components are modular and reusable
4. Follow MVVM pattern established in project guidelines

## Error Handling

- Network errors are gracefully handled with user-friendly messages
- Loading states provide visual feedback during AI processing
- Fallback messages for failed AI responses
- Automatic retry capabilities built into the service layer

## Future Enhancements

- Voice input/output capabilities
- Integration with user's reading history
- Personalized recommendations based on purchase history
- Multi-language support
- Chat export functionality
