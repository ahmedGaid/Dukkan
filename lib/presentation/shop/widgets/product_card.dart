import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/product/entities/product.dart';
import '../../../domain/product/entities/stock_status.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/price_tag.dart';
import '../../widgets/common/shimmer_image.dart';

/// A product tile in the shop grid: image, localized name, price, and an
/// add-to-cart control that morphs from an "add" pill into a quantity stepper.
///
/// The quantity here is **local and ephemeral** — C2b is browse-only. C3 wires
/// [onQuantityChanged] to the real cart bloc so the count survives navigation;
/// until then it's a self-contained interaction preview.
class ProductCard extends StatefulWidget {
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
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _qty = 0;

  void _setQty(int next) => setState(() => _qty = next.clamp(0, 99));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final product = widget.product;
    final name = isArabic ? product.nameAr : product.name;
    final soldOut = product.stockStatus == StockStatus.outOfStock;

    return AppCard(
      onTap: widget.onTap,
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
                    top: AppSpacing.sm,
                    end: AppSpacing.sm,
                    child: _Badge(
                      label: l10n.productStockLow,
                      background: AppColors.warning.withValues(alpha: 0.16),
                      foreground: AppColors.warning,
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
                if (widget.subtitle != null) ...[
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
                          widget.subtitle!,
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
                      : _AddControl(
                          qty: _qty,
                          onAdd: () => _setQty(1),
                          onIncrement: () => _setQty(_qty + 1),
                          onDecrement: () => _setQty(_qty - 1),
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

/// The "add" pill ↔ quantity stepper. `qty == 0` shows the pill; tapping it (or
/// the "+") raises the count; "−" at 1 returns to the pill.
class _AddControl extends StatelessWidget {
  const _AddControl({
    required this.qty,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    if (qty == 0) {
      return Material(
        color: scheme.primary,
        borderRadius: AppRadius.roundAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onAdd,
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

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.roundAll,
        border: Border.all(color: scheme.primary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
            semanticLabel: l10n.qtyDecrease,
          ),
          Text(
            '$qty',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
            semanticLabel: l10n.qtyIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Icon(
          icon,
          size: 20,
          color: scheme.primary,
          semanticLabel: semanticLabel,
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
