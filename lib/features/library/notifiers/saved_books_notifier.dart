import 'package:flutter/foundation.dart';

class SavedBooksNotifier extends ChangeNotifier {
  static final SavedBooksNotifier _instance = SavedBooksNotifier._internal();

  factory SavedBooksNotifier() {
    return _instance;
  }

  SavedBooksNotifier._internal();

  void notifyBookSavedStatusChanged() {
    notifyListeners();
  }
}
