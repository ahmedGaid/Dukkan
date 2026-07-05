import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/shop/entities/shop.dart';

/// One filled star + the average + the rating count, e.g. "★ 4.5 (12)".
/// Renders nothing for an unrated shop — no "no ratings yet" clutter on a
/// card that already reads fine without it (P3).
class ShopRatingBadge extends StatelessWidget {
  const ShopRatingBadge({super.key, required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final average = shop.averageRating;
    if (average == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 15, color: AppColors.warning),
        const SizedBox(width: 2),
        Text(average.toStringAsFixed(1), style: text.bodySmall),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '(${shop.ratingCount})',
          style: text.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
