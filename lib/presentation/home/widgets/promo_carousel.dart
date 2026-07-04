import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// One promo banner's content. In C2a these are brand welcome messages; P1
/// wires the carousel to real `isPromo` product flags.
class PromoBanner {
  const PromoBanner({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

/// Calm mint banners with a dot indicator. Auto-advances gently unless
/// reduced-motion is on (then it's swipe-only). One brand green — never the
/// loud red ribbons of the reference app.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key, required this.banners});

  final List<PromoBanner> banners;

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
    if (reduceMotion || widget.banners.length < 2) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % widget.banners.length;
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
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: _Banner(banner: widget.banners[i]),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Dots(count: widget.banners.length, active: _page),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.banner});

  final PromoBanner banner;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.xlAll,
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.primary, AppColors.primaryBright],
        ),
      ),
      child: Stack(
        children: [
          // Soft watermark glyph in the trailing corner.
          PositionedDirectional(
            end: -8,
            bottom: -12,
            child: Icon(
              banner.icon,
              size: 96,
              color: AppColors.surface.withValues(alpha: 0.14),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                banner.title,
                style: text.titleMedium?.copyWith(color: AppColors.surface),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                banner.body,
                style: text.bodyMedium?.copyWith(
                  color: AppColors.surface.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
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
