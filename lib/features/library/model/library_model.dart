import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryBook {
  final String id;
  final String userId;
  final String bookId;
  final String title;
  final String author;
  final String? coverUrl;
  final String? isbn;
  final String bookType; // 'ebook' or 'physical'
  final double purchasePrice;
  final DateTime purchaseDate;
  final String transactionId;
  final String sellerId;
  final String sellerName;

  final int? currentPage;
  final int? totalPages;
  final DateTime? lastReadDate;
  final bool isCompleted;

  final String? downloadUrl;
  final bool isDownloaded;
  final String? localFilePath;

  LibraryBook({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.title,
    required this.author,
    this.coverUrl,
    this.isbn,
    required this.bookType,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.transactionId,
    required this.sellerId,
    required this.sellerName,
    this.currentPage,
    this.totalPages,
    this.lastReadDate,
    this.isCompleted = false,
    this.downloadUrl,
    this.isDownloaded = false,
    this.localFilePath,
  });

  double get readingProgress {
    if (totalPages == null || currentPage == null || totalPages == 0) {
      return 0.0;
    }
    return (currentPage! / totalPages!).clamp(0.0, 1.0);
  }

  bool get isEbook => bookType.toLowerCase() == 'ebook';

  bool get isPhysicalBook => bookType.toLowerCase() == 'physical';

  factory LibraryBook.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LibraryBook(
      id: doc.id,
      userId: data['userId'] ?? '',
      bookId: data['bookId'] ?? '',
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      coverUrl: data['coverUrl'],
      isbn: data['isbn'],
      bookType: data['bookType'] ?? 'physical',
      purchasePrice: (data['purchasePrice'] ?? 0.0).toDouble(),
      purchaseDate:
          (data['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      transactionId: data['transactionId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      currentPage: data['currentPage'],
      totalPages: data['totalPages'],
      lastReadDate: (data['lastReadDate'] as Timestamp?)?.toDate(),
      isCompleted: data['isCompleted'] ?? false,
      downloadUrl: data['downloadUrl'],
      isDownloaded: data['isDownloaded'] ?? false,
      localFilePath: data['localFilePath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'isbn': isbn,
      'bookType': bookType,
      'purchasePrice': purchasePrice,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'transactionId': transactionId,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'lastReadDate':
          lastReadDate != null ? Timestamp.fromDate(lastReadDate!) : null,
      'isCompleted': isCompleted,
      'downloadUrl': downloadUrl,
      'isDownloaded': isDownloaded,
      'localFilePath': localFilePath,
    };
  }

  LibraryBook copyWith({
    String? id,
    String? userId,
    String? bookId,
    String? title,
    String? author,
    String? coverUrl,
    String? isbn,
    String? bookType,
    double? purchasePrice,
    DateTime? purchaseDate,
    String? transactionId,
    String? sellerId,
    String? sellerName,
    int? currentPage,
    int? totalPages,
    DateTime? lastReadDate,
    bool? isCompleted,
    String? downloadUrl,
    bool? isDownloaded,
    String? localFilePath,
  }) {
    return LibraryBook(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      isbn: isbn ?? this.isbn,
      bookType: bookType ?? this.bookType,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      transactionId: transactionId ?? this.transactionId,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      isCompleted: isCompleted ?? this.isCompleted,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}

class LibraryStats {
  final int totalBooks;
  final int ebooks;
  final int physicalBooks;
  final int completedBooks;
  final int inProgressBooks;
  final double totalSpent;

  LibraryStats({
    required this.totalBooks,
    required this.ebooks,
    required this.physicalBooks,
    required this.completedBooks,
    required this.inProgressBooks,
    required this.totalSpent,
  });
}
