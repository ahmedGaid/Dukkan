import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/product/entities/product.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/price_tag.dart';
import '../../widgets/common/shimmer_image.dart';

/// Calm mint-gradient-scrimmed banners with a dot indicator, one real
/// `isPromo` product each (P1 — replaces the static brand-welcome copy from
/// C2a). Auto-advances gently unless reduced-motion is on (then swipe-only).
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key, required this.products, required this.onTap});

  final List<Product> products;
  final ValueChanged<Product> onTap;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _maybeAutoAdvance(bool reduceMotion) {
    if (reduceMotion || widget.products.length < 2) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % widget.products.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _maybeAutoAdvance(reduceMotion);

    return Column(
      children: [
        SizedBox(
          height: 132,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.products.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: _Banner(
                product: widget.products[i],
                onTap: () => widget.onTap(widget.products[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Dots(count: widget.products.length, active: _page),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = isArabic ? product.nameAr : product.name;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.xlAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ShimmerImage(
              url: product.imageUrl,
              radius: BorderRadius.zero,
              fallbackIcon: Icons.shopping_basket_outlined,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.primary.withValues(alpha: 0.78),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              top: AppSpacing.sm,
              start: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBright,
                  borderRadius: AppRadius.roundAll,
                ),
                child: Text(
                  l10n.promoBadge,
                  style: text.labelSmall?.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              bottom: AppSpacing.md,
              start: AppSpacing.md,
              end: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(color: AppColors.surface),
                  ),
                  const SizedBox(height: 2),
                  PriceTag(
                    product.priceMinor,
                    style: text.titleSmall?.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == active
                  ? scheme.secondary
                  : scheme.onSurface.withValues(alpha: 0.18),
              borderRadius: AppRadius.roundAll,
            ),
          ),
      ],
    );
  }
}
