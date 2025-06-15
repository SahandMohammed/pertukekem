import 'package:flutter/material.dart';
import '../../model/store_model.dart';
import '../../widgets/store_rating_widget.dart';
import '../../../listings/model/listing_model.dart';
import '../../../listings/view/listing_details_screen.dart';
import '../../../../core/services/listing_service.dart';

class StoreDetailsScreen extends StatefulWidget {
  final StoreModel store;

  const StoreDetailsScreen({super.key, required this.store});

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  final ListingService _listingService = ListingService();
  List<Listing> _storeListings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStoreListings();
  }

  Future<void> _loadStoreListings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch listings for this store using the store ID
      final listings = await _listingService.fetchSellerListings(
        widget.store.storeId,
        'store',
      );

      setState(() {
        _storeListings = listings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
          // App Bar with Store Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorScheme.primary, colorScheme.primaryContainer],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Store Logo
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child:
                                  widget.store.logoUrl != null &&
                                          widget.store.logoUrl!.isNotEmpty
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          widget.store.logoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return _buildStorePlaceholder();
                                          },
                                        ),
                                      )
                                      : _buildStorePlaceholder(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widget.store.storeName,
                                          style: textTheme.headlineSmall
                                              ?.copyWith(
                                                color: colorScheme.onPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (widget.store.isVerified) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.verified,
                                          color: colorScheme.onPrimary,
                                          size: 24,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Rating
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.store.rating.toStringAsFixed(1)}',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${widget.store.totalRatings} reviews)',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onPrimary
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ), // Store Information Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStoreInfoSection(),
                  const SizedBox(height: 24),
                  _buildListingsSection(), // Moved up
                  const SizedBox(height: 24),
                  _buildRatingsSection(), // Moved down
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.store,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        size: 40,
      ),
    );
  }

  Widget _buildStoreInfoSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Store',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            if (widget.store.description != null &&
                widget.store.description!.isNotEmpty) ...[
              Text(
                widget.store.description!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ], // Contact Information
            if (widget.store.contactInfo.isNotEmpty) ...[
              _buildInfoRow(
                Icons.location_on_outlined,
                'Address',
                widget.store.storeAddress != null
                    ? widget.store.storeAddress!['street'] ?? 'Not provided'
                    : 'Not provided',
              ),
              const SizedBox(height: 12), // Email and Phone from contact info
              ...widget.store.contactInfo.map((contact) {
                IconData icon =
                    contact['type'] == 'email'
                        ? Icons.email_outlined
                        : Icons.phone_outlined;
                String label = contact['type'] == 'email' ? 'Email' : 'Phone';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildInfoRow(icon, label, contact['value'] ?? ''),
                );
              }).toList(),
            ], // Categories
            if (widget.store.categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Specializes in:',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    widget.store.categories.map((category) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ], // Business Hours
            if (widget.store.businessHours?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Business Hours',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  _buildCurrentStatusBadge(),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children:
                      widget.store.businessHours!.entries.map((entry) {
                        final hourData = _parseBusinessHours(entry.value);
                        final isLast =
                            entry == widget.store.businessHours!.entries.last;
                        final isToday = _isToday(entry.key);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isToday
                                    ? colorScheme.primary.withOpacity(0.05)
                                    : null,
                            border:
                                isLast
                                    ? null
                                    : Border(
                                      bottom: BorderSide(
                                        color: colorScheme.outline.withOpacity(
                                          0.1,
                                        ),
                                      ),
                                    ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (isToday) ...[
                                    Container(
                                      width: 4,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    _formatDayName(entry.key),
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight:
                                          isToday
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                      color:
                                          isToday
                                              ? colorScheme.primary
                                              : colorScheme.onSurface,
                                    ),
                                  ),
                                  if (isToday) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '(Today)',
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                children: [
                                  if (hourData['isOpen'] == true) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${hourData['openTime']} - ${hourData['closeTime']}',
                                        style: textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.errorContainer
                                            .withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Closed',
                                        style: textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListingsSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Books from ${widget.store.storeName}',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_storeListings.length} books',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading books',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadStoreListings,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (_storeListings.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No books available',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This store hasn\'t listed any books yet.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: _storeListings.length,
            itemBuilder: (context, index) {
              final listing = _storeListings[index];
              return _buildListingCard(listing);
            },
          ),
      ],
    );
  }

  Widget _buildListingCard(Listing listing) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListingDetailsScreen(listing: listing),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: colorScheme.surfaceVariant,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    listing.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildBookPlaceholder();
                    },
                  ),
                ),
              ),
            ),

            // Book Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.author,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${listing.price.toStringAsFixed(2)}',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                listing.condition == 'new'
                                    ? colorScheme.primaryContainer
                                    : colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            listing.condition.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color:
                                  listing.condition == 'new'
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookPlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.book,
          size: 48,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildRatingsSection() {
    return StoreRatingWidget(
      storeId: widget.store.storeId,
      storeName: widget.store.storeName,
    );
  }

  Widget _buildCurrentStatusBadge() {
    final textTheme = Theme.of(context).textTheme;

    // Find today's hours
    final today = DateTime.now();
    final weekdays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final todayName = weekdays[today.weekday - 1];

    final todayEntry = widget.store.businessHours!.entries.firstWhere(
      (entry) =>
          entry.key.toLowerCase() == todayName ||
          entry.key.toLowerCase() == todayName.substring(0, 3),
      orElse: () => MapEntry('', null),
    );

    if (todayEntry.key.isEmpty) {
      return const SizedBox.shrink();
    }

    final hourData = _parseBusinessHours(todayEntry.value);
    final isOpen = hourData['isOpen'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isOpen
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isOpen
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOpen ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'Open' : 'Closed',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDayName(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
      case 'mon':
        return 'Monday';
      case 'tuesday':
      case 'tue':
        return 'Tuesday';
      case 'wednesday':
      case 'wed':
        return 'Wednesday';
      case 'thursday':
      case 'thu':
        return 'Thursday';
      case 'friday':
      case 'fri':
        return 'Friday';
      case 'saturday':
      case 'sat':
        return 'Saturday';
      case 'sunday':
      case 'sun':
        return 'Sunday';
      default:
        return day.substring(0, 1).toUpperCase() +
            day.substring(1).toLowerCase();
    }
  }

  Map<String, dynamic> _parseBusinessHours(dynamic hours) {
    if (hours == null) {
      return {'isOpen': false, 'openTime': '', 'closeTime': ''};
    }

    if (hours is String) {
      // Handle simple string format like "09:00 - 17:00" or "Closed"
      if (hours.toLowerCase() == 'closed') {
        return {'isOpen': false, 'openTime': '', 'closeTime': ''};
      }

      if (hours.contains(' - ')) {
        final parts = hours.split(' - ');
        return {
          'isOpen': true,
          'openTime': parts[0].trim(),
          'closeTime': parts[1].trim(),
        };
      }

      return {'isOpen': false, 'openTime': '', 'closeTime': ''};
    }

    if (hours is Map<String, dynamic>) {
      // Handle the actual structure: {isOpen: true, closeTime: 18:00, openTime: 09:00}
      bool isOpen = hours['isOpen'] ?? false;
      String openTime = hours['openTime']?.toString() ?? '';
      String closeTime = hours['closeTime']?.toString() ?? '';

      // Also check alternative key names
      openTime =
          openTime.isEmpty ? (hours['open']?.toString() ?? '') : openTime;
      closeTime =
          closeTime.isEmpty ? (hours['close']?.toString() ?? '') : closeTime;

      return {'isOpen': isOpen, 'openTime': openTime, 'closeTime': closeTime};
    }

    return {'isOpen': false, 'openTime': '', 'closeTime': ''};
  }

  bool _isToday(String day) {
    final today = DateTime.now();
    final weekdays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final todayName = weekdays[today.weekday - 1];
    return day.toLowerCase() == todayName ||
        day.toLowerCase() ==
            todayName.substring(
              0,
              3,
            ); // Handle both full and abbreviated day names
  }
}
