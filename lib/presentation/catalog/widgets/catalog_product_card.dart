import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/product/entities/product.dart';
import '../../../domain/product/entities/stock_status.dart';
import '../../../domain/product/usecases/delete_product.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/price_tag.dart';
import '../../widgets/common/shimmer_image.dart';
import '../../widgets/common/status_chip.dart';
import '../pages/product_form_page.dart';

String _stockLabel(AppLocalizations l10n, StockStatus status) => switch (status) {
      StockStatus.inStock => l10n.productStockIn,
      StockStatus.lowStock => l10n.productStockLow,
      StockStatus.outOfStock => l10n.productStockOut,
    };

StatusTone _stockTone(StockStatus status) => switch (status) {
      StockStatus.inStock => StatusTone.positive,
      StockStatus.lowStock => StatusTone.caution,
      StockStatus.outOfStock => StatusTone.caution,
    };

/// An owner's product tile in the S2 catalog manager: tap to edit, a trailing
/// delete button with a confirm dialog. No add-to-cart control — that's
/// `ProductCard`'s job on the customer side.
class CatalogProductCard extends StatelessWidget {
  const CatalogProductCard({
    super.key,
    required this.product,
    required this.shopId,
  });

  final Product product;
  final String shopId;

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.productDeleteConfirmTitle),
        content: Text(l10n.productDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await sl<DeleteProduct>()(product.id);
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBar.error(context, l10n.productDeleteErrorBody);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = isArabic ? product.nameAr : product.name;

    return AppCard(
      onTap: () => context.push(
        '/catalog/product-form',
        extra: ProductFormArgs(shopId: shopId, product: product),
      ),
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
                PositionedDirectional(
                  top: AppSpacing.sm,
                  end: AppSpacing.sm,
                  child: _DeleteButton(onTap: () => _delete(context)),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                PriceTag(product.priceMinor),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusChip(
                      label: _stockLabel(l10n, product.stockStatus),
                      tone: _stockTone(product.stockStatus),
                    ),
                    if (product.isPromo)
                      StatusChip(
                        label: l10n.promoBadge,
                        tone: StatusTone.positive,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small circular delete affordance over the image corner — visible on any
/// photo, distinct from the edit-by-tap gesture on the rest of the card.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
        ),
      ),
    );
  }
}
