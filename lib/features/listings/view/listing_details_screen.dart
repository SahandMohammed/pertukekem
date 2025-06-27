import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../model/listing_model.dart';
import '../model/review_model.dart';
import '../../dashboards/model/store_model.dart';
import '../../../core/services/review_service.dart';
import '../../authentication/viewmodel/auth_viewmodel.dart';
import '../../payments/view/payment_screen.dart';
import '../../library/service/library_service.dart';
import '../../library/service/saved_books_service.dart';
import '../../cart/services/cart_service.dart';
import '../../cart/view/cart_screen.dart';

class ListingDetailsScreen extends StatefulWidget {
  final Listing listing;

  const ListingDetailsScreen({super.key, required this.listing});

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  final ReviewService _reviewService = ReviewService();
  final LibraryService _libraryService = LibraryService();
  final SavedBooksService _savedBooksService = SavedBooksService();
  StoreModel? _storeInfo;
  Map<String, dynamic>? _reviewStats;
  bool _isLoadingStore = true;
  bool _isLoadingReviews = true;
  bool _isCheckingOwnership = true;
  bool _userOwnsBook = false;
  bool _isStoreAccount = false;
  bool _isBookSaved = false;
  bool _isLoadingSavedState = true;
  Listing get listing => widget.listing;

  bool get _isAnyLoading =>
      _isLoadingStore ||
      _isLoadingReviews ||
      _isCheckingOwnership ||
      _isLoadingSavedState;
  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
    _loadReviewStats();
    _checkBookOwnership();
    _checkUserType();
    _checkSavedState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartService>().initializeCart();
    });
  }

  Future<void> _loadStoreInfo() async {
    if (listing.sellerType != 'store') {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _isLoadingStore = false);
      return;
    }

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
    if (currentUser == null || listing.id == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _isCheckingOwnership = false);
      return;
    }

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

  Future<void> _checkUserType() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isStoreAccount = false);
      return;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final roles = userData?['roles'] as List<dynamic>?;

        setState(() {
          _isStoreAccount = roles?.contains('store') ?? false;
        });
      } else {
        setState(() => _isStoreAccount = false);
      }
    } catch (e) {
      debugPrint('Error checking user type: $e');
      setState(() => _isStoreAccount = false);
    }
  }

  Future<void> _checkSavedState() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || listing.id == null) {
      setState(() => _isLoadingSavedState = false);
      return;
    }

    setState(() => _isLoadingSavedState = true);
    try {
      final isSaved = await _savedBooksService.isBookSaved(listing.id!);
      setState(() {
        _isBookSaved = isSaved;
      });
    } catch (e) {
      debugPrint('Error checking saved state: $e');
    } finally {
      setState(() => _isLoadingSavedState = false);
    }
  }

  Future<void> _toggleSavedState() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to save books'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (listing.id == null) return;

    try {
      if (_isBookSaved) {
        await _savedBooksService.unsaveBook(listing.id!);
        setState(() => _isBookSaved = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book removed from saved'),
            backgroundColor: Colors.grey,
          ),
        );
      } else {
        String sellerId = '';
        String sellerName = '';

        if (listing.sellerType == 'store' && _storeInfo != null) {
          sellerId = listing.sellerRef.id;
          sellerName = _storeInfo!.storeName;
        } else {
          try {
            final userDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(listing.sellerRef.id)
                    .get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              sellerId = listing.sellerRef.id;
              sellerName =
                  userData['displayName'] ??
                  userData['email'] ??
                  'Unknown Seller';
            }
          } catch (e) {
            sellerId = listing.sellerRef.id;
            sellerName = 'Unknown Seller';
          }
        }

        await _savedBooksService.saveBookFromListing(
          listing,
          sellerId,
          sellerName,
        );
        setState(() => _isBookSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book saved to your collection'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildShimmerPlaceholder() {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
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
                  onPressed: () {},
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
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: 240,
                      height: 320,
                      margin: const EdgeInsets.only(top: 60),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

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
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 32,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 20,
                        width: 200,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(height: 32),

                      ...List.generate(
                        5,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Container(
                                height: 16,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                height: 16,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Container(
                        height: 20,
                        width: 100,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        3,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Container(
                        height: 20,
                        width: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(
                        2,
                        (index) => Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 16,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceVariant,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        height: 12,
                                        width: 80,
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceVariant,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 16,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 16,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildShimmerBottomButton(),
    );
  }

  Widget _buildShimmerBottomButton() {

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            Colors
                .white, // Consider using colorScheme.surface here if appropriate for the design
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 15,
            offset: const Offset(0, -3),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: SafeArea(
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color:
                  Colors
                      .grey
                      .shade300, // Also update the container's placeholder color
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isAnyLoading) {
      return _buildShimmerPlaceholder();
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
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
              Consumer<AuthViewModel>(
                builder: (context, authViewModel, child) {
                  final userRoles = authViewModel.user?.roles ?? [];
                  final isCustomer = userRoles.contains('customer');

                  if (!isCustomer) return const SizedBox.shrink();

                  return Consumer<CartService>(
                    builder: (context, cartService, child) {
                      return Container(
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
                        child: Stack(
                          children: [
                            IconButton(
                              onPressed: () => _navigateToCart(context),
                              icon: const Icon(Icons.shopping_cart_outlined),
                            ),
                            if (cartService.itemCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${cartService.itemCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
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
                  onPressed: _toggleSavedState,
                  icon:
                      _isLoadingSavedState
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                            ),
                          )
                          : Icon(
                            _isBookSaved
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                _isBookSaved
                                    ? Colors.red
                                    : colorScheme.onSurface,
                          ),
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
                    _buildTitleSection(context),
                    const SizedBox(height: 24),

                    _buildPriceAndConditionSection(context),
                    const SizedBox(height: 32),

                    _buildDetailsSection(context),
                    const SizedBox(height: 32),

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
          ),
        ],
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
                  '\$${listing.price.toStringAsFixed(2)}',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
            if (!_isStoreAccount)
              TextButton.icon(
                onPressed: () => _showAddReviewDialog(context),
                icon: Icon(Icons.add, size: 18),
                label: Text('Write Review'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
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

    if (_isStoreAccount) {
      return const SizedBox.shrink();
    }

    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final userRoles = authViewModel.user?.roles ?? [];
        final isCustomer = userRoles.contains('customer');

        final bool showOwnershipInfo = isCustomer && _userOwnsBook;

        final Color textColor =
            showOwnershipInfo
                ? colorScheme.onSurfaceVariant
                : colorScheme.onPrimary;
        return Container(
          width: double.infinity,

          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 3,
                offset: const Offset(0, -3),
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: SafeArea(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient:
                    showOwnershipInfo
                        ? LinearGradient(
                          colors: [
                            colorScheme.surfaceVariant,
                            colorScheme.surfaceVariant.withOpacity(0.8),
                          ],
                        )
                        : LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withOpacity(0.9),
                          ],
                        ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color:
                        showOwnershipInfo
                            ? colorScheme.surfaceVariant.withOpacity(0.3)
                            : colorScheme.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    if (isCustomer) {
                      _showBuyNowDialog(context);
                    } else {
                      _showContactDialog(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: textColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            showOwnershipInfo
                                ? Icons.library_books_rounded
                                : (isCustomer
                                    ? (listing.bookType == 'physical'
                                        ? Icons.shopping_cart_rounded
                                        : Icons.shopping_bag_rounded)
                                    : Icons.message_rounded),
                            color: textColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Consumer<CartService>(
                            builder: (context, cartService, child) {
                              final isInCart =
                                  isCustomer && listing.bookType == 'physical'
                                      ? cartService.isInCart(listing.id ?? '')
                                      : false;
                              return Text(
                                showOwnershipInfo
                                    ? 'View in Library'
                                    : (listing.sellerType == 'store'
                                        ? (isCustomer
                                            ? (listing.bookType == 'physical'
                                                ? (isInCart
                                                    ? 'View Cart'
                                                    : 'Add to Cart')
                                                : 'Buy Now')
                                            : 'Contact Store')
                                        : 'Contact Seller'),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: textColor.withOpacity(0.8),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
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
    if (_userOwnsBook) {
      _showAlreadyOwnedDialog(context);
      return;
    }

    if (listing.sellerType != 'store') {
      _showContactDialog(context);
      return;
    }

    if (listing.bookType == 'ebook') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(listing: listing),
        ),
      );
    } else {
      final cartService = context.read<CartService>();
      final isInCart = cartService.isInCart(listing.id ?? '');

      if (isInCart) {
        _navigateToCart(context);
      } else {
        _addToCart(context);
      }
    }
  }

  Future<void> _addToCart(BuildContext context) async {
    final cartService = context.read<CartService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Adding to cart...'),
              ],
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final success = await cartService.addToCart(listing);
      if (mounted) {
        if (success) {
          scaffoldMessenger.hideCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(child: Text('${listing.title} added to cart!')),
                  TextButton(
                    onPressed: () {
                      scaffoldMessenger.hideCurrentSnackBar();
                      _navigateToCart(context);
                    },
                    child: const Text(
                      'VIEW CART',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          scaffoldMessenger.hideCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 16),
                  const Text('Failed to add to cart. Please try again.'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToCart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
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

          const SizedBox(height: 12),
          Text(
            review.comment,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),

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
    if (_isStoreAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Store accounts cannot write reviews')),
      );
      return;
    }

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

    if (_isStoreAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Store accounts cannot write reviews')),
      );
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
