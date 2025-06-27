import 'package:flutter/foundation.dart';

class LibraryNotifier extends ChangeNotifier {
  static final LibraryNotifier _instance = LibraryNotifier._internal();

  factory LibraryNotifier() {
    return _instance;
  }

  LibraryNotifier._internal();

  void notifyBookAddedToLibrary() {
    if (kDebugMode) {
      print('LibraryNotifier: Book added to library, notifying listeners');
    }
    notifyListeners();
  }

  void notifyLibraryChanged() {
    if (kDebugMode) {
      print('LibraryNotifier: Library changed, notifying listeners');
    }
    notifyListeners();
  }
}
