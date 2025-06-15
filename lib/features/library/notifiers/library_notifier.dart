import 'package:flutter/foundation.dart';

/// A singleton notifier that manages library change notifications
/// This allows different parts of the app to listen for library updates
/// and refresh the library data accordingly
class LibraryNotifier extends ChangeNotifier {
  static final LibraryNotifier _instance = LibraryNotifier._internal();

  factory LibraryNotifier() {
    return _instance;
  }

  LibraryNotifier._internal();

  /// Notify all listeners that a book has been added to the library
  /// This should be called after a successful ebook purchase
  void notifyBookAddedToLibrary() {
    if (kDebugMode) {
      print('LibraryNotifier: Book added to library, notifying listeners');
    }
    notifyListeners();
  }

  /// Notify all listeners that the library data has changed
  /// This can be used for other library-related changes
  void notifyLibraryChanged() {
    if (kDebugMode) {
      print('LibraryNotifier: Library changed, notifying listeners');
    }
    notifyListeners();
  }
}
