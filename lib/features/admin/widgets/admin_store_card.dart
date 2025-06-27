import 'package:flutter/material.dart';
import '../model/admin_store_model.dart';

class AdminStoreCard extends StatelessWidget {
  final AdminStoreModel store;
  final Function(bool) onToggleBlock;

  const AdminStoreCard({
    super.key,
    required this.store,
    required this.onToggleBlock,
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child:
                      store.logoUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              store.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      _buildFallbackLogo(),
                            ),
                          )
                          : _buildFallbackLogo(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.storeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Owner: ${store.ownerName}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        store.ownerEmail,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
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
                        store.status,
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildStatItem(
                  Icons.star,
                  '${store.rating.toStringAsFixed(1)} (${store.totalRatings})',
                  Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  Icons.book,
                  '${store.totalListings} listings',
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  Icons.category,
                  '${store.categories.length} categories',
                  Colors.green,
                ),
              ],
            ),

            if (store.description != null) ...[
              const SizedBox(height: 12),
              Text(
                store.description!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Created ${_formatDate(store.createdAt)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const Spacer(),
                if (store.categories.isNotEmpty) ...[
                  Wrap(
                    spacing: 4.0,
                    children:
                        store.categories.take(3).map((category) {
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
                  if (store.categories.length > 3)
                    Text(
                      ' +${store.categories.length - 3}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                ],
              ],
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => onToggleBlock(!store.isBlocked),
                  icon: Icon(
                    store.isBlocked ? Icons.check : Icons.block,
                    size: 16,
                  ),
                  label: Text(store.isBlocked ? 'Unblock' : 'Block'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        store.isBlocked ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
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

  Widget _buildFallbackLogo() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(Icons.store, color: Colors.grey.shade600, size: 24),
    );
  }

  Widget _buildStatItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Color _getStatusColor() {
    if (store.isBlocked) return Colors.red;
    if (store.isVerified) return Colors.green;
    return Colors.orange;
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
