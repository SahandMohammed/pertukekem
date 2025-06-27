import 'package:flutter/material.dart';
import '../model/admin_listing_model.dart';

class AdminListingCard extends StatelessWidget {
  final AdminListingModel listing;
  final VoidCallback onRemove;

  const AdminListingCard({
    super.key,
    required this.listing,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.grey.shade200,
                  ),
                  child:
                      listing.coverUrl.isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              listing.coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      _buildFallbackCover(),
                            ),
                          )
                          : _buildFallbackCover(),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${listing.author}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriceColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              listing.formattedPrice,
                              style: TextStyle(
                                color: _getPriceColor(),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: _getConditionColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              listing.condition.toUpperCase(),
                              style: TextStyle(
                                color: _getConditionColor(),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        listing.statusText,
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color:
                            listing.bookType == 'ebook'
                                ? Colors.purple.shade100
                                : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            listing.bookType == 'ebook'
                                ? Icons.download
                                : Icons.book,
                            size: 12,
                            color:
                                listing.bookType == 'ebook'
                                    ? Colors.purple.shade700
                                    : Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            listing.bookType == 'ebook' ? 'E-book' : 'Physical',
                            style: TextStyle(
                              color:
                                  listing.bookType == 'ebook'
                                      ? Colors.purple.shade700
                                      : Colors.blue.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  listing.sellerType == 'store' ? Icons.store : Icons.person,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Seller: ${listing.sellerName}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color:
                        listing.sellerType == 'store'
                            ? Colors.blue.shade100
                            : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    listing.sellerType == 'store' ? 'Store' : 'Individual',
                    style: TextStyle(
                      color:
                          listing.sellerType == 'store'
                              ? Colors.blue.shade700
                              : Colors.green.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Created ${_formatDate(listing.createdAt)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),

            if (listing.category.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4.0,
                runSpacing: 4.0,
                children:
                    listing.category.take(3).map((category) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (listing.status != 'removed')
                  ElevatedButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      'REMOVED',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackCover() {
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(Icons.book, color: Colors.grey.shade600, size: 30),
    );
  }

  Color _getPriceColor() {
    return Colors.green.shade600;
  }

  Color _getConditionColor() {
    return listing.condition == 'new' ? Colors.green : Colors.orange;
  }

  Color _getStatusColor() {
    switch (listing.status) {
      case 'active':
        return Colors.green;
      case 'sold':
        return Colors.blue;
      case 'inactive':
        return Colors.orange;
      case 'removed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return 'Today';
    }
  }
}
