import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/cart_icon_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeletons.dart';
import '../bloc/shops_bloc.dart';
import '../widgets/category_grid.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/shop_card.dart';

/// Customer Home — the marketplace entry. Leads with shops + categories (Dukkan
/// is a marketplace, not a single store). Owns its [ShopsBloc]; every state
/// (loading / empty / error) is designed.
class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ShopsBloc>()..add(const ShopsStarted()),
      child: const _CustomerHomeView(),
    );
  }
}

class _CustomerHomeView extends StatelessWidget {
  const _CustomerHomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _HomeHeader(),
            Expanded(
              child: BlocBuilder<ShopsBloc, ShopsState>(
                builder: (context, state) => switch (state.status) {
                  ShopsStatus.loading => const _HomeLoading(),
                  ShopsStatus.error => _HomeError(
                      onRetry: () => context
                          .read<ShopsBloc>()
                          .add(const ShopsRetryRequested()),
                    ),
                  ShopsStatus.loaded => _HomeContent(state: state),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logo =
        isDark ? 'assets/brand/logo-dark.png' : 'assets/brand/logo-light.png';

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Image.asset(logo, height: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Material(
              color: scheme.surface,
              borderRadius: AppRadius.roundAll,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.roundAll,
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 20,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.homeSearchHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const CartIconButton(),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.state});

  final ShopsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<ShopsBloc>();
    final banners = [
      PromoBanner(
        title: l10n.promo1Title,
        body: l10n.promo1Body,
        icon: Icons.storefront_outlined,
      ),
      PromoBanner(
        title: l10n.promo2Title,
        body: l10n.promo2Body,
        icon: Icons.delivery_dining_outlined,
      ),
      PromoBanner(
        title: l10n.promo3Title,
        body: l10n.promo3Body,
        icon: Icons.sell_outlined,
      ),
    ];
    final shops = state.visibleShops;

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const ShopsRetryRequested()),
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          PromoCarousel(banners: banners),
          if (state.categories.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(l10n.sectionCategories),
            const SizedBox(height: AppSpacing.md),
            CategoryGrid(
              categories: state.categories,
              selected: state.selectedCategory,
              onSelect: (c) => bloc.add(ShopsCategorySelected(c)),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(l10n.sectionNearbyShops),
          const SizedBox(height: AppSpacing.md),
          if (shops.isEmpty)
            _NearbyEmpty(hasFilter: state.selectedCategory != null)
          else
            for (final shop in shops) ...[
              ShopCard(
                shop: shop,
                onTap: () => context.push('/shop/${shop.id}'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }
}

class _NearbyEmpty extends StatelessWidget {
  const _NearbyEmpty({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<ShopsBloc>();
    if (hasFilter) {
      final selected = bloc.state.selectedCategory;
      return EmptyState(
        icon: Icons.storefront_outlined,
        title: l10n.categoryEmptyTitle,
        message: l10n.categoryEmptyBody,
        actionLabel: l10n.categoryAll,
        onAction: selected == null
            ? null
            : () => bloc.add(ShopsCategorySelected(selected)),
      );
    }
    return EmptyState(
      icon: Icons.storefront_outlined,
      title: l10n.shopsEmptyTitle,
      message: l10n.shopsEmptyBody,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: const [
        SizedBox(
          height: 132,
          child: GridShimmer(count: 1, columns: 1, aspectRatio: 2.6),
        ),
        SizedBox(height: AppSpacing.lg),
        GridShimmer(count: 6, columns: 3, aspectRatio: 0.92),
        SizedBox(height: AppSpacing.lg),
        ListShimmer(count: 4),
      ],
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: l10n.errorTitle,
      message: l10n.errorBody,
      actionLabel: l10n.actionRetry,
      onAction: onRetry,
    );
  }
}
