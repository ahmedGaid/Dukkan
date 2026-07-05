import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/shop/entities/shop.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/widgets/shop_card.dart';
import '../../shop/widgets/product_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeletons.dart';
import '../bloc/favorites_page_bloc.dart';

/// The customer "Favorites" tab: saved shops in a list, saved products in a
/// grid. Owns its [FavoritesPageBloc]; every state (loading/empty/error) is
/// designed. Replaces the P0 `ComingSoonPage` placeholder.
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<FavoritesPageBloc>()..add(const FavoritesPageStarted()),
      child: const _FavoritesView(),
    );
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(l10n.navFavorites, style: text.headlineSmall),
            ),
            Expanded(
              child: BlocBuilder<FavoritesPageBloc, FavoritesPageState>(
                builder: (context, state) => switch (state.status) {
                  FavoritesPageStatus.loading => const _FavoritesLoading(),
                  FavoritesPageStatus.error => _FavoritesError(
                      onRetry: () => context
                          .read<FavoritesPageBloc>()
                          .add(const FavoritesPageRetryRequested()),
                    ),
                  FavoritesPageStatus.loaded => state.isEmpty
                      ? const _FavoritesEmpty()
                      : _FavoritesContent(state: state),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesContent extends StatelessWidget {
  const _FavoritesContent({required this.state});

  final FavoritesPageState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        if (state.favoriteShops.isNotEmpty) ...[
          Text(l10n.favoritesSectionShops, style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final shop in state.favoriteShops) ...[
            ShopCard(shop: shop, onTap: () => context.push('/shop/${shop.id}')),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
        if (state.favoriteProducts.isNotEmpty) ...[
          if (state.favoriteShops.isNotEmpty)
            const SizedBox(height: AppSpacing.sm),
          Text(l10n.favoritesSectionProducts, style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: state.favoriteProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.58,
            ),
            itemBuilder: (context, i) {
              final product = state.favoriteProducts[i];
              final Shop? shop = state.shopsById[product.shopId];
              final shopName =
                  shop == null ? null : (isArabic ? shop.nameAr : shop.name);
              return ProductCard(
                key: ValueKey(product.id),
                product: product,
                subtitle: shopName,
                onTap: () => context.push(
                  '/shop/${product.shopId}/product/${product.id}',
                  extra: product,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _FavoritesEmpty extends StatelessWidget {
  const _FavoritesEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.favorite_border_rounded,
      title: l10n.favoritesEmptyTitle,
      message: l10n.favoritesEmptyBody,
    );
  }
}

class _FavoritesLoading extends StatelessWidget {
  const _FavoritesLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          ListShimmer(count: 2, itemHeight: 88),
          SizedBox(height: AppSpacing.lg),
          GridShimmer(count: 4, columns: 2, aspectRatio: 0.58),
        ],
      ),
    );
  }
}

class _FavoritesError extends StatelessWidget {
  const _FavoritesError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: l10n.errorTitle,
      message: l10n.favoritesErrorBody,
      actionLabel: l10n.actionRetry,
      onAction: onRetry,
    );
  }
}
