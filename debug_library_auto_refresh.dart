
import 'package:flutter/foundation.dart';
import 'lib/features/library/notifiers/library_notifier.dart';

class LibraryAutoRefreshTest {
  static void simulateEbookPurchase() {
    if (kDebugMode) {
      print('=== TESTING LIBRARY AUTO-REFRESH ===');
      print('1. Simulating ebook purchase completion...');


      print('2. Triggering library notifier...');

      final libraryNotifier = LibraryNotifier();
      libraryNotifier.notifyBookAddedToLibrary();

      print('3. Library notifier triggered!');
      print('4. Library tab should automatically refresh now.');
      print('5. Library view model should reload all data.');
      print('=== TEST COMPLETE ===');
    }
  }

  static void setupTestListener() {
    if (kDebugMode) {
      print('Setting up test listener for library changes...');

      final libraryNotifier = LibraryNotifier();
      libraryNotifier.addListener(() {
        print('📚 Library change detected! UI should refresh now.');
      });

      print('Test listener setup complete.');
      print('Now call simulateEbookPurchase() to test the flow.');
    }
  }
}
