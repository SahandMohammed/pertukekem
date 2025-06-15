import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/library_model.dart';
import '../../listings/model/listing_model.dart';

class SavedBooksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add a book to user's favorites from a LibraryBook
  Future<void> saveBook(LibraryBook book) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // Create a saved book document in the user's savedBooks subcollection
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('savedBooks')
          .doc(book.bookId) // Use bookId as the document ID for consistency
          .set({
            'bookId': book.bookId,
            'title': book.title,
            'author': book.author,
            'isbn': book.isbn,
            'coverUrl': book.coverUrl,
            'bookType': book.bookType,
            'downloadUrl': book.downloadUrl,
            'totalPages': book.totalPages,
            'currentPage': book.currentPage,
            'userId': currentUser.uid,
            'sellerId': book.sellerId,
            'sellerName': book.sellerName,
            'savedAt': FieldValue.serverTimestamp(),
            'purchaseDate': Timestamp.fromDate(book.purchaseDate),
            'purchasePrice': book.purchasePrice,
            'transactionId': book.transactionId,
            'lastReadDate':
                book.lastReadDate != null
                    ? Timestamp.fromDate(book.lastReadDate!)
                    : null,
            'isCompleted': book.isCompleted,
            'localFilePath': book.localFilePath,
            'isDownloaded': book.isDownloaded,
          });

      // Also add the book ID to the user's favorites array for quick lookup
      await _firestore.collection('users').doc(currentUser.uid).update({
        'favorites': FieldValue.arrayUnion([book.bookId]),
      });
    } catch (e) {
      throw Exception('Failed to save book: $e');
    }
  }

  /// Add a book to user's favorites from a Listing
  Future<void> saveBookFromListing(
    Listing listing,
    String sellerId,
    String sellerName,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // Create a saved book document in the user's savedBooks subcollection
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('savedBooks')
          .doc(listing.id!)
          .set({
            'bookId': listing.id!,
            'title': listing.title,
            'author': listing.author,
            'isbn': listing.isbn,
            'coverUrl': listing.coverUrl,
            'bookType': listing.bookType,
            'downloadUrl': listing.ebookUrl,
            'totalPages': listing.pageCount,
            'currentPage': 0,
            'userId': currentUser.uid,
            'sellerId': sellerId,
            'sellerName': sellerName,
            'savedAt': FieldValue.serverTimestamp(),
            'purchaseDate': DateTime.now(), // Not applicable for saved listings
            'purchasePrice': 0.0, // Not applicable for saved listings
            'transactionId': '', // Not applicable for saved listings
            'lastReadDate': null,
            'isCompleted': false,
            'localFilePath': null,
            'isDownloaded': false,
            'description': listing.description,
            'publisher': listing.publisher,
            'language': listing.language,
            'year': listing.year,
            'format': listing.format,
            'condition': listing.condition,
            'price': listing.price,
          });

      // Also add the book ID to the user's favorites array for quick lookup
      await _firestore.collection('users').doc(currentUser.uid).update({
        'favorites': FieldValue.arrayUnion([listing.id!]),
      });
    } catch (e) {
      throw Exception('Failed to save book: $e');
    }
  }

  /// Remove a book from user's favorites
  Future<void> unsaveBook(String bookId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // Remove from savedBooks subcollection
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('savedBooks')
          .doc(bookId)
          .delete();

      // Remove from favorites array
      await _firestore.collection('users').doc(currentUser.uid).update({
        'favorites': FieldValue.arrayRemove([bookId]),
      });
    } catch (e) {
      throw Exception('Failed to unsave book: $e');
    }
  }

  /// Check if a book is saved by the current user
  Future<bool> isBookSaved(String bookId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('savedBooks')
              .doc(bookId)
              .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get all saved books for the current user
  Future<List<LibraryBook>> getSavedBooks() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('savedBooks')
              .orderBy('savedAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return LibraryBook(
          id: doc.id,
          bookId: data['bookId'] ?? '',
          title: data['title'] ?? '',
          author: data['author'] ?? '',
          isbn: data['isbn'],
          coverUrl: data['coverUrl'],
          bookType: data['bookType'] ?? 'physical',
          downloadUrl: data['downloadUrl'],
          totalPages: data['totalPages'],
          currentPage: data['currentPage'] ?? 0,
          userId: data['userId'] ?? '',
          sellerId: data['sellerId'] ?? '',
          sellerName: data['sellerName'] ?? '',
          purchaseDate:
              data['purchaseDate'] != null
                  ? (data['purchaseDate'] as Timestamp).toDate()
                  : DateTime.now(),
          purchasePrice: (data['purchasePrice'] ?? 0.0).toDouble(),
          transactionId: data['transactionId'] ?? '',
          lastReadDate:
              data['lastReadDate'] != null
                  ? (data['lastReadDate'] as Timestamp).toDate()
                  : null,
          isCompleted: data['isCompleted'] ?? false,
          localFilePath: data['localFilePath'],
          isDownloaded: data['isDownloaded'] ?? false,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch saved books: $e');
    }
  }

  /// Stream of saved books for real-time updates
  Stream<List<LibraryBook>> getSavedBooksStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('savedBooks')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return LibraryBook(
              id: doc.id,
              bookId: data['bookId'] ?? '',
              title: data['title'] ?? '',
              author: data['author'] ?? '',
              isbn: data['isbn'],
              coverUrl: data['coverUrl'],
              bookType: data['bookType'] ?? 'physical',
              downloadUrl: data['downloadUrl'],
              totalPages: data['totalPages'],
              currentPage: data['currentPage'] ?? 0,
              userId: data['userId'] ?? '',
              sellerId: data['sellerId'] ?? '',
              sellerName: data['sellerName'] ?? '',
              purchaseDate:
                  data['purchaseDate'] != null
                      ? (data['purchaseDate'] as Timestamp).toDate()
                      : DateTime.now(),
              purchasePrice: (data['purchasePrice'] ?? 0.0).toDouble(),
              transactionId: data['transactionId'] ?? '',
              lastReadDate:
                  data['lastReadDate'] != null
                      ? (data['lastReadDate'] as Timestamp).toDate()
                      : null,
              isCompleted: data['isCompleted'] ?? false,
              localFilePath: data['localFilePath'],
              isDownloaded: data['isDownloaded'] ?? false,
            );
          }).toList();
        });
  }

  /// Get saved books count for stats
  Future<int> getSavedBooksCount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('savedBooks')
              .get();

      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
