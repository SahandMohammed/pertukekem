import 'package:flutter/foundation.dart';

/// A simple notifier to inform when saved books are updated
class SavedBooksNotifier extends ChangeNotifier {
  static final SavedBooksNotifier _instance = SavedBooksNotifier._internal();

  factory SavedBooksNotifier() {
    return _instance;
  }

  SavedBooksNotifier._internal();

  /// Call this method whenever a book is saved or unsaved
  void notifyBookSavedStatusChanged() {
    notifyListeners();
  }
}
