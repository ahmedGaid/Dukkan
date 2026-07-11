import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/product/entities/product.dart';
import '../../../domain/shop/entities/shop.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/cart_icon_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shop_header.dart';
import '../../widgets/common/skeletons.dart';
import '../bloc/products_bloc.dart';
import '../widgets/product_card.dart';

/// A single دكان's page: header (logo, open/closed, address), an in-shop
/// category filter, and the product grid. Owns its [ProductsBloc]; every state
/// (loading / empty / error) is designed. Replaces the C2a `/shop/:id`
/// placeholder.
class ShopPage extends StatelessWidget {
  const ShopPage({super.key, required this.shopId, this.initialCategory});

  final String shopId;

  /// Category selected on Home (M5) — carried in as the initial filter so the
  /// shop opens pre-filtered instead of showing everything then re-filtering.
  final String? initialCategory;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductsBloc>(param1: shopId, param2: initialCategory)
        ..add(const ProductsStarted()),
      child: ShopView(shopId: shopId),
    );
  }
}

/// Split from [ShopPage] so it sits under the [BlocProvider] and product cards
/// can route with the shop id in scope.
class ShopView extends StatelessWidget {
  const ShopView({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: BlocSelector<ProductsBloc, ProductsState, Shop?>(
          selector: (state) => state.shop,
          builder: (context, shop) {
            if (shop == null) return const SizedBox.shrink();
            return Text(isArabic ? shop.nameAr : shop.name);
          },
        ),
        actions: const [CartIconButton()],
      ),
      body: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) => switch (state.status) {
          ProductsStatus.loading => const _ShopLoading(),
          ProductsStatus.error => _ShopError(
              onRetry: () => context
                  .read<ProductsBloc>()
                  .add(const ProductsRetryRequested()),
            ),
          ProductsStatus.loaded => _ShopContent(state: state, shopId: shopId),
        },
      ),
    );
  }
}

class _ShopContent extends StatelessWidget {
  const _ShopContent({required this.state, required this.shopId});

  final ProductsState state;
  final String shopId;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductsBloc>();
    final shop = state.shop;
    final products = state.visibleProducts;

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const ProductsRetryRequested()),
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          if (shop != null) ShopHeader(shop: shop),
          if (state.categories.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _CategoryFilterRow(
              categories: state.categories,
              selected: state.selectedCategory,
              onSelect: (c) => bloc.add(ProductsCategorySelected(c)),
              onSelectAll: () {
                final selected = state.selectedCategory;
                if (selected != null) {
                  bloc.add(ProductsCategorySelected(selected));
                }
              },
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (products.isEmpty)
            _ProductsEmpty(hasFilter: state.selectedCategory != null)
          else
            _ProductGrid(products: products, shopId: shopId),
        ],
      ),
    );
  }
}

/// Horizontal chips: "All" plus one per catalog category. The active chip reads
/// as selected; tapping it again (or "All") clears the filter.
class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.onSelectAll,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _FilterChip(
              label: l10n.categoryAll,
              selected: selected == null,
              onTap: onSelectAll,
            );
          }
          final category = categories[i - 1];
          return _FilterChip(
            label: category,
            selected: category == selected,
            onTap: () => onSelect(category),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      color: selected ? scheme.primary : scheme.surface,
      borderRadius: AppRadius.roundAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.roundAll,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
            ),
          ),
          child: Text(
            label,
            style: text.bodySmall?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products, required this.shopId});

  final List<Product> products;
  final String shopId;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.64,
      ),
      itemBuilder: (context, i) {
        final product = products[i];
        return ProductCard(
          key: ValueKey(product.id),
          product: product,
          onTap: () => context.push(
            '/shop/$shopId/product/${product.id}',
            extra: product,
          ),
        );
      },
    );
  }
}

class _ProductsEmpty extends StatelessWidget {
  const _ProductsEmpty({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<ProductsBloc>();
    if (hasFilter) {
      final selected = bloc.state.selectedCategory;
      return EmptyState(
        icon: Icons.shopping_basket_outlined,
        title: l10n.productsCategoryEmptyTitle,
        message: l10n.productsCategoryEmptyBody,
        actionLabel: l10n.categoryAll,
        onAction: selected == null
            ? null
            : () => bloc.add(ProductsCategorySelected(selected)),
      );
    }
    return EmptyState(
      icon: Icons.shopping_basket_outlined,
      title: l10n.shopProductsEmptyTitle,
      message: l10n.shopProductsEmptyBody,
    );
  }
}

class _ShopLoading extends StatelessWidget {
  const _ShopLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: const [
        ListShimmer(count: 1, itemHeight: 72),
        SizedBox(height: AppSpacing.lg),
        GridShimmer(count: 6, columns: 2, aspectRatio: 0.64),
      ],
    );
  }
}

class _ShopError extends StatelessWidget {
  const _ShopError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: l10n.errorTitle,
      message: l10n.shopErrorBody,
      actionLabel: l10n.actionRetry,
      onAction: onRetry,
    );
  }
}
