import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../cart/model/cart_item_model.dart';

class OrderItemCard extends StatelessWidget {
  final CartItem item;
  final bool isLast;

  const OrderItemCard({super.key, required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                ),
      ),
      child: Row(
        children: [
          _buildBookCover(context),
          const SizedBox(width: 16),
          Expanded(child: _buildBookInfo(context)),
          _buildPriceInfo(context),
        ],
      ),
    );
  }

  Widget _buildBookCover(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Hero(
      tag: 'book-${item.listing.id}',
      child: Container(
        width: 60,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              item.listing.coverUrl.isNotEmpty
                  ? Image.network(
                    item.listing.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.book_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      );
                    },
                  )
                  : Container(
                    color: colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.book_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildBookInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.listing.title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (item.listing.author.isNotEmpty)
          Text(
            'by ${item.listing.author}',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Qty: ${item.quantity}',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          NumberFormat.currency(symbol: r'$').format(item.totalPrice),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        if (item.quantity > 1) ...[
          const SizedBox(height: 4),
          Text(
            '${NumberFormat.currency(symbol: r'$').format(item.listing.price)} each',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
