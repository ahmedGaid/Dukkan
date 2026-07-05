import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The one heart toggle — a translucent circular tap target so it reads over
/// any image, reused on `ShopCard`, `ProductCard`, and product detail. Filled
/// + brand-error red when favorited; outlined + muted otherwise (color always
/// pairs with the icon shape change, never carries meaning alone).
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.size = 20,
  });

  final bool isFavorite;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: size,
            color: isFavorite ? AppColors.error : scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
