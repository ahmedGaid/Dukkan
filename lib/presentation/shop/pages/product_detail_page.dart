import 'package:flutter/material.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/product/entities/product.dart';
import '../../../domain/product/entities/stock_status.dart';
import '../../../domain/product/usecases/get_product.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/price_tag.dart';
import '../../widgets/common/shimmer.dart';
import '../../widgets/common/shimmer_image.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/common/status_chip.dart';

/// Full product view: large image, name, price, stock, a quantity selector and
/// an add-to-cart CTA. Usually seeded with the [Product] the grid already holds
/// (no load flash); falls back to [GetProduct] for a cold/deep-link open.
///
/// The cart itself lands in C3 — the CTA here confirms the intent but doesn't
/// yet persist a basket.
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.productId, this.seed});

  final String productId;
  final Product? seed;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? _product;
  bool _loading = false;
  bool _failed = false;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    if (widget.seed != null) {
      _product = widget.seed;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final product = await sl<GetProduct>()(widget.productId);
      if (!mounted) return;
      setState(() {
        _product = product;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _setQty(int next) => setState(() => _qty = next.clamp(1, 99));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final product = _product;
    final title = product == null
        ? ''
        : (isArabic ? product.nameAr : product.name);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Builder(
        builder: (context) {
          if (_loading) return const _DetailLoading();
          if (_failed || product == null) {
            return EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: l10n.productNotFoundTitle,
              message: l10n.productNotFoundBody,
              actionLabel: widget.seed == null ? l10n.actionRetry : null,
              onAction: widget.seed == null ? _load : null,
            );
          }
          return _DetailContent(
            product: product,
            qty: _qty,
            onIncrement: () => _setQty(_qty + 1),
            onDecrement: () => _setQty(_qty - 1),
          );
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.product,
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Product product;
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = isArabic ? product.nameAr : product.name;
    final soldOut = product.stockStatus == StockStatus.outOfStock;

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ShimmerImage(
                url: product.imageUrl,
                radius: AppRadius.xlAll,
                fallbackIcon: Icons.shopping_basket_outlined,
              ),
            ),
            if (product.isPromo)
              PositionedDirectional(
                top: AppSpacing.md,
                start: AppSpacing.md,
                child: _PromoTag(label: l10n.promoBadge),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(name, style: text.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        PriceTag(
          product.priceMinor,
          style: text.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _StockLine(status: product.stockStatus),
        const SizedBox(height: AppSpacing.xl),
        if (soldOut)
          const _SoldOutBlock()
        else ...[
          _QuantityRow(
            qty: qty,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
          ),
          const SizedBox(height: AppSpacing.lg),
          _AddToCartButton(product: product, qty: qty),
        ],
      ],
    );
  }
}

/// A word + tinted pill describing shelf state (reuses the shared [StatusChip]
/// tones). In-stock stays quiet — no chip — so only a nudge (low) or a block
/// (out) draws the eye.
class _StockLine extends StatelessWidget {
  const _StockLine({required this.status});

  final StockStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (status) {
      StockStatus.inStock => StatusChip(
          label: l10n.productStockIn,
          tone: StatusTone.positive,
        ),
      StockStatus.lowStock => StatusChip(
          label: l10n.productStockLow,
          tone: StatusTone.caution,
        ),
      StockStatus.outOfStock => StatusChip(
          label: l10n.productStockOut,
          tone: StatusTone.caution,
        ),
    };
  }
}

class _QuantityRow extends StatelessWidget {
  const _QuantityRow({
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(l10n.qtyLabel, style: text.titleSmall),
        const Spacer(),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.roundAll,
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: onDecrement,
                semanticLabel: l10n.qtyDecrease,
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$qty',
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                onTap: onIncrement,
                semanticLabel: l10n.qtyIncrease,
              ),
            ],
          ),
        ),
      ],
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
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          icon,
          size: 22,
          color: scheme.primary,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.product, required this.qty});

  final Product product;
  final int qty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => AppSnackBar.info(context, l10n.cartComingSoon),
        icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
        label: Text(l10n.actionAddToCart),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundAll),
        ),
      ),
    );
  }
}

/// Sold-out replacement for the quantity + CTA block — a designed, worded state
/// rather than a greyed, silent button.
class _SoldOutBlock extends StatelessWidget {
  const _SoldOutBlock();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: AppRadius.roundAll,
      ),
      child: Text(
        l10n.productStockOut,
        style: text.titleSmall?.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PromoTag extends StatelessWidget {
  const _PromoTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryBright,
        borderRadius: AppRadius.roundAll,
      ),
      child: Text(
        label,
        style: text.labelLarge?.copyWith(
          color: AppColors.surface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        AspectRatio(aspectRatio: 1, child: ShimmerBox(radius: AppRadius.xlAll)),
        const SizedBox(height: AppSpacing.lg),
        const ListShimmer(count: 1, itemHeight: 28),
      ],
    );
  }
}
