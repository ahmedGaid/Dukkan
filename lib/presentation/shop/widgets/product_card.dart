import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/product/entities/product.dart';
import '../../../domain/product/entities/stock_status.dart';
import '../../../l10n/app_localizations.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../cart/cart_actions.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import '../../favorites/favorite_actions.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/favorite_button.dart';
import '../../widgets/common/price_tag.dart';
import '../../widgets/common/quantity_stepper.dart';
import '../../widgets/common/shimmer_image.dart';

/// A product tile in the shop/search grid: image, localized name, price, and
/// an add-to-cart control that morphs from an "add" pill into the shared
/// [QuantityStepper] once the product is in the cart.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.subtitle,
  });

  final Product product;

  /// Opens the product detail page.
  final VoidCallback onTap;

  /// Secondary line under the name — the shop name in global search results,
  /// where the same product could come from any دكان. Null on a shop page (the
  /// shop is already the context).
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = isArabic ? product.nameAr : product.name;
    final soldOut = product.stockStatus == StockStatus.outOfStock;

    return AppCard(
      onTap: onTap,
      clip: true,
      radius: AppRadius.lgAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ShimmerImage(
                  url: product.imageUrl,
                  radius: BorderRadius.zero,
                  fallbackIcon: Icons.shopping_basket_outlined,
                ),
                // Dim the image so a sold-out product reads as unavailable.
                if (soldOut)
                  ColoredBox(
                    color: AppColors.surface.withValues(alpha: 0.55),
                  ),
                if (product.isPromo)
                  PositionedDirectional(
                    top: AppSpacing.sm,
                    start: AppSpacing.sm,
                    child: _Badge(
                      label: l10n.promoBadge,
                      background: AppColors.primaryBright,
                      foreground: AppColors.surface,
                    ),
                  ),
                if (product.stockStatus == StockStatus.lowStock)
                  PositionedDirectional(
                    bottom: AppSpacing.sm,
                    end: AppSpacing.sm,
                    child: _Badge(
                      label: l10n.productStockLow,
                      background: AppColors.warning.withValues(alpha: 0.16),
                      foreground: AppColors.warning,
                    ),
                  ),
                PositionedDirectional(
                  top: AppSpacing.sm,
                  end: AppSpacing.sm,
                  child: BlocSelector<FavoritesBloc, FavoritesState, bool>(
                    selector: (state) => state.isProductFavorite(product.id),
                    builder: (context, isFavorite) => FavoriteButton(
                      isFavorite: isFavorite,
                      size: 18,
                      onTap: () => toggleFavoriteProduct(context, product.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                PriceTag(product.priceMinor),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 36,
                  width: double.infinity,
                  child: soldOut
                      ? const _SoldOutLabel()
                      : BlocSelector<CartBloc, CartState, int>(
                          selector: (state) => state.quantityOf(product.id),
                          builder: (context, qty) => qty == 0
                              ? _AddPill(onTap: () => addToCart(context, product))
                              : QuantityStepper(
                                  expand: true,
                                  qty: qty,
                                  onIncrement: () => context
                                      .read<CartBloc>()
                                      .add(CartItemIncremented(product.id)),
                                  onDecrement: () => context
                                      .read<CartBloc>()
                                      .add(CartItemDecremented(product.id)),
                                ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small corner pill over the product image (promo / low-stock).
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.roundAll,
      ),
      child: Text(
        label,
        style: text.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The initial "add" pill — tapping it adds one unit; the control then morphs
/// into a [QuantityStepper] bound to the real cart.
class _AddPill extends StatelessWidget {
  const _AddPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.primary,
      borderRadius: AppRadius.roundAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 18, color: scheme.onPrimary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              l10n.actionAdd,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The disabled control shown when a product is out of stock — a calm caution
/// label, never a dead-looking greyed button with no words.
class _SoldOutLabel extends StatelessWidget {
  const _SoldOutLabel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: AppRadius.roundAll,
      ),
      child: Text(
        l10n.productStockOut,
        style: text.labelLarge?.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
