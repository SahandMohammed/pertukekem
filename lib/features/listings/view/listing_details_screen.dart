import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../model/listing_model.dart';
import '../model/review_model.dart';
import '../../dashboards/store/models/store_model.dart';
import '../../../core/services/review_service.dart';
import '../../authentication/viewmodels/auth_viewmodel.dart';
import '../../payments/screens/payment_screen.dart';
import '../../library/services/library_service.dart';

class ListingDetailsScreen extends StatefulWidget {
  final Listing listing;

  const ListingDetailsScreen({super.key, required this.listing});

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  final ReviewService _reviewService = ReviewService();
  final LibraryService _libraryService = LibraryService();
  StoreModel? _storeInfo;
  Map<String, dynamic>? _reviewStats;
  bool _isLoadingStore = false;
  bool _isLoadingReviews = false;
  bool _isCheckingOwnership = false;
  bool _userOwnsBook = false;

  Listing get listing => widget.listing;
  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
    _loadReviewStats();
    _checkBookOwnership();
  }

  Future<void> _loadStoreInfo() async {
    if (listing.sellerType != 'store') return;

    setState(() => _isLoadingStore = true);
    try {
      final storeDoc =
          await FirebaseFirestore.instance
              .collection('stores')
              .doc(listing.sellerRef.id)
              .get();

      if (storeDoc.exists) {
        setState(() {
          _storeInfo = StoreModel.fromMap(storeDoc.data()!);
        });
      }
    } catch (e) {
      debugPrint('Error loading store info: $e');
    } finally {
      setState(() => _isLoadingStore = false);
    }
  }

  Future<void> _loadReviewStats() async {
    setState(() => _isLoadingReviews = true);
    try {
      final stats = await _reviewService.getListingReviewStats(listing.id!);
      setState(() {
        _reviewStats = stats;
      });
    } catch (e) {
      debugPrint('Error loading review stats: $e');
    } finally {
      setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _checkBookOwnership() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || listing.id == null) return;

    setState(() => _isCheckingOwnership = true);
    try {
      final ownsBook = await _libraryService.userOwnsBook(listing.id!);
      setState(() {
        _userOwnsBook = ownsBook;
      });
    } catch (e) {
      debugPrint('Error checking book ownership: $e');
    } finally {
      setState(() => _isCheckingOwnership = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar with Cover Image
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            elevation: 0,
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    // TODO: Add to favorites/share functionality
                  },
                  icon: const Icon(Icons.favorite_border),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.surfaceVariant.withOpacity(0.3),
                      colorScheme.surfaceVariant,
                    ],
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'listing-${listing.id}',
                    child: Container(
                      width: 240,
                      height: 320,
                      margin: const EdgeInsets.only(top: 60),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          listing.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: colorScheme.surfaceVariant,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.book_outlined,
                                    size: 64,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No Cover Available',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Title and Basic Info
                    _buildTitleSection(context),
                    const SizedBox(height: 24),

                    // Price and Condition
                    _buildPriceAndConditionSection(context),
                    const SizedBox(height: 32),

                    // Book Details
                    _buildDetailsSection(context),
                    const SizedBox(height: 32),

                    // Description
                    if (listing.description != null) ...[
                      _buildDescriptionSection(context),
                      const SizedBox(height: 32),
                    ], // Reviews Section
                    _buildReviewsSection(context),
                    const SizedBox(height: 100), // Space for floating button
                  ],
                ),
              ),
            ),
          ),        ],
      ),
      bottomNavigationBar: _buildContactSellerButton(context),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                listing.title,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${listing.id}',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.person_outline,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'by ${listing.author}',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ), // Show store name under author if it's a store seller
        if (listing.sellerType == 'store') ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.store_outlined, size: 16, color: colorScheme.primary),
              const SizedBox(width: 4),
              if (_isLoadingStore)
                SizedBox(
                  width: 100,
                  height: 16,
                  child: LinearProgressIndicator(
                    backgroundColor: colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                )
              else if (_storeInfo != null) ...[
                Text(
                  _storeInfo!.storeName,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_storeInfo!.isVerified) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.verified, size: 16, color: colorScheme.primary),
                ],
              ] else
                Text(
                  'Store information unavailable',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
        if (listing.publisher != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.business_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                listing.publisher!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              listing.category.map((category) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    category,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceAndConditionSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'USD ${listing.price.toStringAsFixed(2)}',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  listing.condition == 'new'
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    listing.condition == 'new' ? Colors.green : Colors.orange,
                width: 1.5,
              ),
            ),
            child: Text(
              listing.condition.toUpperCase(),
              style: textTheme.labelLarge?.copyWith(
                color:
                    listing.condition == 'new'
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Book Details',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                context,
                'ISBN',
                listing.isbn,
                Icons.qr_code_outlined,
              ),
              if (listing.language != null)
                _buildDetailRow(
                  context,
                  'Language',
                  listing.language!,
                  Icons.language_outlined,
                ),
              if (listing.format != null)
                _buildDetailRow(
                  context,
                  'Format',
                  listing.format!,
                  Icons.auto_stories_outlined,
                ),
              if (listing.pageCount != null)
                _buildDetailRow(
                  context,
                  'Pages',
                  '${listing.pageCount} pages',
                  Icons.description_outlined,
                ),
              if (listing.year != null)
                _buildDetailRow(
                  context,
                  'Published',
                  listing.year!.toString(),
                  Icons.calendar_today_outlined,
                ),
              _buildDetailRow(
                context,
                'Listed',
                _formatDate(listing.createdAt),
                Icons.schedule_outlined,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Text(
            listing.description!,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddReviewDialog(context),
              icon: Icon(Icons.add, size: 18),
              label: Text('Write Review'),
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 16), // Review Stats
        if (_isLoadingReviews)
          Container(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_reviewStats != null) ...[
          _buildReviewStats(context),
          const SizedBox(height: 20),
        ],

        // Reviews List
        StreamBuilder<List<ReviewModel>>(
          stream: _reviewService.getListingReviews(listing.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Error loading reviews: ${snapshot.error}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              );
            }

            final reviews = snapshot.data ?? [];

            if (reviews.isEmpty) {
              return Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No reviews yet',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Be the first to review this book!',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children:
                  reviews
                      .take(3)
                      .map((review) => _buildReviewCard(context, review))
                      .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContactSellerButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final userRoles = authViewModel.user?.roles ?? [];
        final isCustomer = userRoles.contains('customer');

        // Determine button appearance based on ownership status
        final bool showOwnershipInfo = isCustomer && _userOwnsBook;
        final Color buttonColor =
            showOwnershipInfo
                ? colorScheme.surfaceVariant
                : colorScheme.primary;        final Color textColor =
            showOwnershipInfo
                ? colorScheme.onSurfaceVariant
                : colorScheme.onPrimary;        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface.withOpacity(0.0),
                colorScheme.surface.withOpacity(0.9),
                colorScheme.surface,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (isCustomer) {
                    _showBuyNowDialog(context);
                  } else {
                    _showContactDialog(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: textColor,
                  elevation: showOwnershipInfo ? 2 : 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                label: Text(
                  showOwnershipInfo
                      ? 'View in Library'
                      : (isCustomer ? 'Buy Now' : 'Contact Seller'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: Icon(
                  showOwnershipInfo
                      ? Icons.library_books
                      : (isCustomer
                          ? Icons.shopping_cart
                          : Icons.message_outlined),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Contact Seller'),
            content: const Text(
              'Contact functionality will be implemented based on your preferred messaging system (chat, email, phone, etc.).',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showBuyNowDialog(BuildContext context) {
    // Check if user already owns this book
    if (_userOwnsBook) {
      _showAlreadyOwnedDialog(context);
      return;
    }

    // Navigate to payment screen for eBooks
    if (listing.bookType == 'ebook') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(listing: listing),
        ),
      );
    } else {
      // For physical books, show the existing dialog
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Purchase Book'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book: ${listing.title}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Price: RM ${listing.price.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  const Text(
                    'For physical books, please contact the seller to arrange payment and delivery.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _contactSeller(context);
                  },
                  child: const Text('Contact Seller'),
                ),
              ],
            ),
      );
    }
  }

  void _showAlreadyOwnedDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.library_books, color: colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                const Text('Already Owned'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You already own "${listing.title}" in your library.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can access this book anytime from your library.',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to library or show access to the book
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Navigate to library feature will be implemented.',
                      ),
                      backgroundColor: colorScheme.primary,
                    ),
                  );
                },
                child: const Text('Go to Library'),
              ),
            ],
          ),
    );
  }

  void _contactSeller(BuildContext context) {
    // TODO: Implement seller contact functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Seller contact functionality will be implemented.',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  Widget _buildReviewStats(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stats = _reviewStats!;
    final totalReviews = stats['totalReviews'] as int;
    final averageRating = stats['averageRating'] as double;
    final ratingDistribution = stats['ratingDistribution'] as Map<int, int>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Average Rating
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalReviews review${totalReviews != 1 ? 's' : ''}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Rating Distribution
              Expanded(
                flex: 3,
                child: Column(
                  children:
                      [5, 4, 3, 2, 1].map((rating) {
                        final count = ratingDistribution[rating] ?? 0;
                        final percentage =
                            totalReviews > 0 ? count / totalReviews : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 8,
                                child: Text(
                                  '$rating',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 4),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  backgroundColor: colorScheme.outlineVariant
                                      .withOpacity(0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 16,
                                child: Text(
                                  '$count',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: Colors.amber, size: size);
        } else if (index < rating) {
          return Icon(Icons.star_half, color: Colors.amber, size: size);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: size);
        }
      }),
    );
  }

  Widget _buildReviewCard(BuildContext context, ReviewModel review) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer Info and Rating
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage:
                    review.reviewerAvatar != null
                        ? NetworkImage(review.reviewerAvatar!)
                        : null,
                child:
                    review.reviewerAvatar == null
                        ? Icon(
                          Icons.person,
                          color: colorScheme.onPrimaryContainer,
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.reviewerName,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (review.isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Verified',
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        _buildStarRating(review.rating, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(Timestamp.fromDate(review.createdAt)),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Review Comment
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),

          // Seller Reply
          if (review.replyFromSeller != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.store, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Seller Reply',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (review.replyDate != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(Timestamp.fromDate(review.replyDate!)),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review.replyFromSeller!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Helpful Actions
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _toggleHelpful(review.reviewId),
                icon: Icon(
                  review.helpfulBy.contains(
                        FirebaseAuth.instance.currentUser?.uid,
                      )
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  size: 16,
                ),
                label: Text('Helpful (${review.helpfulBy.length})'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Write a Review'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rating',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                rating = (index + 1).toDouble();
                              });
                            },
                            child: Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 32,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Comment',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: commentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Share your thoughts about this book...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          () => _submitReview(
                            context,
                            rating,
                            commentController.text,
                          ),
                      child: Text('Submit Review'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _submitReview(
    BuildContext context,
    double rating,
    String comment,
  ) async {
    if (comment.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a comment')));
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please sign in to leave a review')),
        );
        return;
      }

      // Get user info
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final userData = userDoc.data();
      final userName =
          userData != null
              ? '${userData['firstName']} ${userData['lastName']}'
              : 'Anonymous User';

      await _reviewService.addReview(
        listingId: listing.id!,
        rating: rating,
        comment: comment.trim(),
        reviewerName: userName,
        reviewerAvatar: userData?['profileImageUrl'],
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Review submitted successfully!')));

      // Refresh review stats
      _loadReviewStats();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting review: $e')));
    }
  }

  Future<void> _toggleHelpful(String reviewId) async {
    try {
      await _reviewService.toggleReviewHelpfulness(reviewId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
