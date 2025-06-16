import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../model/library_model.dart';
import '../../listings/model/listing_model.dart';
import '../notifiers/library_notifier.dart';

class LibraryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a book to user's library after purchase
  Future<void> addBookToLibrary({
    required String userId,
    required Listing listing,
    required DateTime purchaseDate,
    String? orderId,
    String? transactionId,
  }) async {
    final libraryBook = LibraryBook(
      id: listing.id ?? '',
      userId: userId,
      bookId: listing.id ?? '',
      title: listing.title,
      author: listing.author,
      coverUrl: listing.coverUrl,
      isbn: listing.isbn,
      bookType: listing.bookType,
      purchasePrice: listing.price,
      purchaseDate: purchaseDate,
      transactionId: transactionId ?? '',
      sellerId: listing.sellerRef.id,
      sellerName: '',
      totalPages: listing.pageCount,
      downloadUrl: listing.ebookUrl,
    );
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('library')
        .doc(libraryBook.id)
        .set(libraryBook.toMap());

    // Notify listeners that a book has been added to the library
    LibraryNotifier().notifyBookAddedToLibrary();
  }

  // Get user's library books
  Future<List<LibraryBook>> getUserLibrary({
    String? bookType,
    int? limit,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    Query query = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('library')
        .orderBy('purchaseDate', descending: true);

    if (bookType != null) {
      query = query.where('bookType', isEqualTo: bookType);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => LibraryBook.fromFirestore(doc)).toList();
  }

  // Get recently purchased books
  Future<List<LibraryBook>> getRecentlyPurchased({int limit = 5}) async {
    return getUserLibrary(limit: limit);
  }

  // Get books currently reading (ebooks with progress)
  Future<List<LibraryBook>> getCurrentlyReading({int limit = 5}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final snapshot =
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('library')
            .where('bookType', isEqualTo: 'ebook')
            .where('isCompleted', isEqualTo: false)
            .where('currentPage', isGreaterThan: 0)
            .orderBy('lastReadDate', descending: true)
            .limit(limit)
            .get();

    return snapshot.docs.map((doc) => LibraryBook.fromFirestore(doc)).toList();
  }

  // Get ebooks only
  Future<List<LibraryBook>> getEbooks({int? limit}) async {
    return getUserLibrary(bookType: 'ebook', limit: limit);
  }

  // Get physical books only
  Future<List<LibraryBook>> getPhysicalBooks({int? limit}) async {
    return getUserLibrary(bookType: 'physical', limit: limit);
  }

  // Check if user owns a specific book
  Future<bool> userOwnsBook(String bookId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return false;
    }

    final snapshot =
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('library')
            .where('bookId', isEqualTo: bookId)
            .limit(1)
            .get();

    return snapshot.docs.isNotEmpty;
  }

  // Get specific library book
  Future<LibraryBook?> getLibraryBook(String bookId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    final snapshot =
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('library')
            .where('bookId', isEqualTo: bookId)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      return LibraryBook.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Update reading progress
  Future<void> updateReadingProgress({
    required String libraryBookId,
    required int currentPage,
    bool? isCompleted,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final updateData = {
      'currentPage': currentPage,
      'lastReadDate': Timestamp.fromDate(DateTime.now()),
    };

    if (isCompleted != null) {
      updateData['isCompleted'] = isCompleted;
    }

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('library')
        .doc(libraryBookId)
        .update(updateData);
  }

  // Mark book as downloaded
  Future<void> markAsDownloaded({
    required String libraryBookId,
    required String localFilePath,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('library')
        .doc(libraryBookId)
        .update({'isDownloaded': true, 'localFilePath': localFilePath});
  }

  // Remove download information and file
  Future<void> removeDownload(String libraryBookId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the book details first to get the local file path
      final bookDoc =
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('library')
              .doc(libraryBookId)
              .get();

      if (bookDoc.exists) {
        final book = LibraryBook.fromFirestore(bookDoc);

        // Delete the physical file if it exists
        if (book.localFilePath != null && book.localFilePath!.isNotEmpty) {
          final file = File(book.localFilePath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      // Update the database
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('library')
          .doc(libraryBookId)
          .update({
            'isDownloaded': false,
            'localFilePath': FieldValue.delete(),
          });

      // Notify listeners that the library has changed
      LibraryNotifier().notifyLibraryChanged();
    } catch (e) {
      throw Exception('Failed to remove download: $e');
    }
  }

  // Get library statistics
  Future<LibraryStats> getLibraryStats() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final snapshot =
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('library')
            .get();

    final books =
        snapshot.docs.map((doc) => LibraryBook.fromFirestore(doc)).toList();

    final totalBooks = books.length;
    final ebooks = books.where((book) => book.isEbook).length;
    final physicalBooks = books.where((book) => book.isPhysicalBook).length;
    final completedBooks = books.where((book) => book.isCompleted).length;
    final inProgressBooks =
        books
            .where(
              (book) =>
                  book.isEbook &&
                  !book.isCompleted &&
                  (book.currentPage ?? 0) > 0,
            )
            .length;
    final totalSpent = books.fold<double>(
      0.0,
      (sum, book) => sum + book.purchasePrice,
    );

    return LibraryStats(
      totalBooks: totalBooks,
      ebooks: ebooks,
      physicalBooks: physicalBooks,
      completedBooks: completedBooks,
      inProgressBooks: inProgressBooks,
      totalSpent: totalSpent,
    );
  }

  // Search in user's library
  Future<List<LibraryBook>> searchLibrary(String query) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Get all user's books first, then filter locally
    // Firestore doesn't support advanced text search natively
    final allBooks = await getUserLibrary();

    final lowercaseQuery = query.toLowerCase();
    return allBooks.where((book) {
      return book.title.toLowerCase().contains(lowercaseQuery) ||
          book.author.toLowerCase().contains(lowercaseQuery) ||
          (book.isbn?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Remove book from library (if needed)
  Future<void> removeFromLibrary(String libraryBookId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('library')
        .doc(libraryBookId)
        .delete();
  }

  // Stream user's library for real-time updates
  Stream<List<LibraryBook>> streamUserLibrary({String? bookType}) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.empty();
    }

    Query query = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('library')
        .orderBy('purchaseDate', descending: true);

    if (bookType != null) {
      query = query.where('bookType', isEqualTo: bookType);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => LibraryBook.fromFirestore(doc)).toList(),
    );
  }

  // Download book from Firebase Storage
  Future<String> downloadBook({
    required String libraryBookId,
    required String downloadUrl,
    required String fileName,
    required Function(double) onProgress,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');

      // Create books directory if it doesn't exist
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      // Create the file path
      final filePath = '${booksDir.path}/$fileName';
      final file = File(filePath);

      // Download the file from the URL
      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode == 200) {
        // Write the file
        await file.writeAsBytes(response.bodyBytes);

        // Update the database with the local file path
        await markAsDownloaded(
          libraryBookId: libraryBookId,
          localFilePath: filePath,
        );

        // Notify listeners that the library has changed
        LibraryNotifier().notifyLibraryChanged();

        return filePath;
      } else {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }
}
