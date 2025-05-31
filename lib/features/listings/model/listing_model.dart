import 'package:cloud_firestore/cloud_firestore.dart';

class Listing {
  final String? id;
  final DocumentReference sellerRef;
  final String sellerType;
  final String title;
  final String author;
  final String condition;
  final double price;
  final List<String> category;
  final String isbn;
  final String coverUrl;
  final String? description;
  final String? publisher;
  final String? language;
  final int? pageCount;
  final int? year;
  final String? format;
  final String bookType; // 'physical' or 'ebook'
  final String? ebookUrl; // URL to the eBook file for digital books
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  Listing({
    this.id,
    required this.sellerRef,
    required this.sellerType,
    required this.title,
    required this.author,
    required this.condition,
    required this.price,
    required this.category,
    required this.isbn,
    required this.coverUrl,
    this.description,
    this.publisher,
    this.language,
    this.pageCount,
    this.year,
    this.format,
    required this.bookType,
    this.ebookUrl,
    this.createdAt,
    this.updatedAt,
  }) : assert(price > 0, 'Price must be greater than 0'),
       assert(
         condition == 'new' || condition == 'used',
         'Condition must be "new" or "used"',
       ),
       assert(
         pageCount == null || pageCount > 0,
         'Page count must be greater than 0',
       ),
       assert(
         year == null || (year > 1000 && year <= DateTime.now().year),
         'Year must be valid',
       );
  factory Listing.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Listing(
      id: snapshot.id,
      sellerRef: data?['sellerRef'] as DocumentReference,
      sellerType: data?['sellerType'] as String,
      title: data?['title'] as String,
      author: data?['author'] as String,
      condition: data?['condition'] as String,
      price: (data?['price'] as num).toDouble(),
      category: List<String>.from(data?['category'] as List<dynamic>),
      isbn: data?['isbn'] as String,
      coverUrl: data?['coverUrl'] as String,
      description: data?['description'] as String?,
      publisher: data?['publisher'] as String?,
      language: data?['language'] as String?,
      pageCount:
          data?['pageCount'] != null
              ? (data?['pageCount'] as num).toInt()
              : null,
      year: data?['year'] != null ? (data?['year'] as num).toInt() : null,
      format: data?['format'] as String?,
      bookType: data?['bookType'] as String? ?? 'physical',
      ebookUrl: data?['ebookUrl'] as String?,
      createdAt: data?['createdAt'] as Timestamp?,
      updatedAt: data?['updatedAt'] as Timestamp?,
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) 'id': id,
      'sellerRef': sellerRef,
      'sellerType': sellerType,
      'title': title,
      'author': author,
      'condition': condition,
      'price': price,
      'category': category,
      'isbn': isbn,
      'coverUrl': coverUrl,
      if (description != null) 'description': description,
      if (publisher != null) 'publisher': publisher,
      if (language != null) 'language': language,
      if (pageCount != null) 'pageCount': pageCount,
      if (year != null) 'year': year,
      if (format != null) 'format': format,
      'bookType': bookType,
      if (ebookUrl != null) 'ebookUrl': ebookUrl,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  /// Create a copy of this Listing with the given fields updated
  Listing copyWith({
    String? id,
    DocumentReference? sellerRef,
    String? sellerType,
    String? title,
    String? author,
    String? condition,
    double? price,
    List<String>? category,
    String? isbn,
    String? coverUrl,
    String? description,
    String? publisher,
    String? language,
    int? pageCount,
    int? year,
    String? format,
    String? bookType,
    String? ebookUrl,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Listing(
      id: id ?? this.id,
      sellerRef: sellerRef ?? this.sellerRef,
      sellerType: sellerType ?? this.sellerType,
      title: title ?? this.title,
      author: author ?? this.author,
      condition: condition ?? this.condition,
      price: price ?? this.price,
      category: category ?? this.category,
      isbn: isbn ?? this.isbn,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      publisher: publisher ?? this.publisher,
      language: language ?? this.language,
      pageCount: pageCount ?? this.pageCount,
      year: year ?? this.year,
      format: format ?? this.format,
      bookType: bookType ?? this.bookType,
      ebookUrl: ebookUrl ?? this.ebookUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
