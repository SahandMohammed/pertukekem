import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class StoreRatingDisplay extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double itemSize;
  final bool showText;
  final TextStyle? textStyle;

  const StoreRatingDisplay({
    super.key,
    required this.rating,
    required this.totalRatings,
    this.itemSize = 16,
    this.showText = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBarIndicator(
          rating: rating,
          itemBuilder:
              (context, index) => Icon(Icons.star, color: Colors.amber),
          itemCount: 5,
          itemSize: itemSize,
          direction: Axis.horizontal,
        ),
        if (showText) ...[
          const SizedBox(width: 6),
          Text(
            '${rating.toStringAsFixed(1)} (${totalRatings})',
            style:
                textStyle ??
                textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }
}

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final int starCount;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.color,
    this.starCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return RatingBarIndicator(
      rating: rating,
      itemBuilder:
          (context, index) => Icon(Icons.star, color: color ?? Colors.amber),
      itemCount: starCount,
      itemSize: size,
      direction: Axis.horizontal,
    );
  }
}
