import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/shop/entities/shop.dart';
import '../../../l10n/app_localizations.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import '../../favorites/favorite_actions.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/favorite_button.dart';
import '../../widgets/common/shimmer_image.dart';
import '../../widgets/common/status_chip.dart';

/// A row in the nearby-shops list: logo, localized name, address, and an
/// open/closed chip. Tapping opens the shop page (C2b).
class ShopCard extends StatelessWidget {
  const ShopCard({super.key, required this.shop, required this.onTap});

  final Shop shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = isArabic ? shop.nameAr : shop.name;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          ShimmerImage(url: shop.logoUrl, width: 64, height: 64),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        shop.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                StatusChip(
                  label: shop.isOpen ? l10n.shopOpen : l10n.shopClosed,
                  tone: shop.isOpen ? StatusTone.positive : StatusTone.caution,
                ),
              ],
            ),
          ),
          BlocSelector<FavoritesBloc, FavoritesState, bool>(
            selector: (state) => state.isShopFavorite(shop.id),
            builder: (context, isFavorite) => FavoriteButton(
              isFavorite: isFavorite,
              onTap: () => toggleFavoriteShop(context, shop.id),
            ),
          ),
        ],
      ),
    );
  }
}
