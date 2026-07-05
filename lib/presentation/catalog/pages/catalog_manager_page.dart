import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/product/entities/product.dart';
import '../../../domain/shop/entities/shop.dart';
import '../../../domain/shop/usecases/get_shop_by_owner.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../shop/bloc/products_bloc.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shop_header.dart';
import '../../widgets/common/skeletons.dart';
import '../widgets/catalog_product_card.dart';
import 'product_form_page.dart';

enum _LoadStatus { loading, error, loaded }

/// Owner's home: their own shop's catalog, with add/edit/delete (S2).
/// Replaces the F3 `_OwnerPlaceholder` — S3's order desk lands as a sibling
/// entry point later, not a replacement of this page.
class CatalogManagerPage extends StatefulWidget {
  const CatalogManagerPage({super.key});

  @override
  State<CatalogManagerPage> createState() => _CatalogManagerPageState();
}

class _CatalogManagerPageState extends State<CatalogManagerPage> {
  _LoadStatus _status = _LoadStatus.loading;
  Shop? _shop;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;
    setState(() => _status = _LoadStatus.loading);
    try {
      final shop = await sl<GetShopByOwner>()(user.uid);
      if (!mounted) return;
      setState(() {
        _shop = shop;
        _status = _LoadStatus.loaded;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _LoadStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final shop = _shop;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          shop == null ? l10n.appName : (isArabic ? shop.nameAr : shop.name),
        ),
        actions: [
          IconButton(
            tooltip: l10n.actionLogout,
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      floatingActionButton: shop == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(
                '/catalog/product-form',
                extra: ProductFormArgs(shopId: shop.id),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              icon: const Icon(Icons.add),
              label: Text(l10n.actionAddProduct),
            ),
      body: switch (_status) {
        _LoadStatus.loading => const _CatalogLoading(),
        _LoadStatus.error => EmptyState(
            icon: Icons.wifi_off_rounded,
            title: l10n.errorTitle,
            message: l10n.catalogErrorBody,
            actionLabel: l10n.actionRetry,
            onAction: _loadShop,
          ),
        _LoadStatus.loaded => BlocProvider(
            create: (_) =>
                sl<ProductsBloc>(param1: shop!.id)..add(const ProductsStarted()),
            child: const _CatalogContent(),
          ),
      },
    );
  }
}

class _CatalogContent extends StatelessWidget {
  const _CatalogContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        final bloc = context.read<ProductsBloc>();
        return switch (state.status) {
          ProductsStatus.loading => const _CatalogLoading(),
          ProductsStatus.error => EmptyState(
              icon: Icons.wifi_off_rounded,
              title: l10n.errorTitle,
              message: l10n.catalogErrorBody,
              actionLabel: l10n.actionRetry,
              onAction: () =>
                  bloc.add(const ProductsRetryRequested()),
            ),
          ProductsStatus.loaded => RefreshIndicator(
              onRefresh: () async => bloc.add(const ProductsRetryRequested()),
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                children: [
                  if (state.shop != null) ShopHeader(shop: state.shop!),
                  const SizedBox(height: AppSpacing.lg),
                  if (state.visibleProducts.isEmpty)
                    EmptyState(
                      icon: Icons.shopping_basket_outlined,
                      title: l10n.catalogEmptyTitle,
                      message: l10n.catalogEmptyBody,
                    )
                  else
                    _CatalogGrid(
                      products: state.visibleProducts,
                      shopId: state.shop!.id,
                    ),
                ],
              ),
            ),
        };
      },
    );
  }
}

class _CatalogGrid extends StatelessWidget {
  const _CatalogGrid({required this.products, required this.shopId});

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
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, i) {
        final product = products[i];
        return CatalogProductCard(
          key: ValueKey(product.id),
          product: product,
          shopId: shopId,
        );
      },
    );
  }
}

class _CatalogLoading extends StatelessWidget {
  const _CatalogLoading();

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
        GridShimmer(count: 4, columns: 2, aspectRatio: 0.62),
      ],
    );
  }
}
