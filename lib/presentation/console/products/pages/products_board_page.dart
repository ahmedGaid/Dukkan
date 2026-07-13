import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/admin/entities/permissions.dart';
import '../../../../domain/product/entities/product.dart';
import '../../../../domain/product/entities/stock_status.dart';
import '../../../../domain/shop/entities/shop.dart';
import '../../../../domain/taxonomy/entities/category.dart';
import '../../../../domain/taxonomy/usecases/get_taxonomy.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../catalog/pages/product_form_page.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/shimmer_image.dart';
import '../../../widgets/common/skeletons.dart';
import '../../../widgets/common/status_chip.dart';
import '../bloc/products_board_bloc.dart';

/// The Founder Console product board (`/console/products`, FC8). Real
/// Firestore-filtered, cursor-paginated browsing; a search box switches to an
/// Arabic-folded fold over every product matching the active filters (see
/// `ProductsBoardBloc` doc). Long-press a row to enter selection mode for the
/// bulk dialogs; a single tap always edits (pushes the existing owner
/// `ProductFormPage`) unless already in selection mode.
class ProductsBoardPage extends StatelessWidget {
  const ProductsBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductsBoardBloc>()..add(const ProductsBoardStarted()),
      child: const _ProductsBoardView(),
    );
  }
}

class _ProductsBoardView extends StatelessWidget {
  const _ProductsBoardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<ProductsBoardBloc, ProductsBoardState>(
      listenWhen: (a, b) => b.actionError != null && a.actionError != b.actionError,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.productsBoardActionFailed)));
      },
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const _FilterBar(),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: BlocBuilder<ProductsBoardBloc, ProductsBoardState>(
                buildWhen: (a, b) =>
                    a.status != b.status ||
                    a.visibleProducts != b.visibleProducts ||
                    a.hasMore != b.hasMore ||
                    a.selected != b.selected ||
                    a.isSearching != b.isSearching ||
                    a.searching != b.searching,
                builder: (context, state) => switch (state.status) {
                  ProductsBoardStatus.loading => const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: ListShimmer(),
                    ),
                  ProductsBoardStatus.error => EmptyState(
                      icon: Icons.error_outline,
                      title: l10n.errorTitle,
                      message: l10n.productsBoardErrorBody,
                      actionLabel: l10n.actionRetry,
                      onAction: () => context
                          .read<ProductsBoardBloc>()
                          .add(const ProductsBoardRetryRequested()),
                    ),
                  ProductsBoardStatus.loaded => state.searching
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: ListShimmer(),
                        )
                      : state.visibleProducts.isEmpty
                          ? EmptyState(
                              icon: Icons.inventory_2_outlined,
                              title: l10n.productsBoardEmptyTitle,
                              message: l10n.productsBoardEmptyBody,
                            )
                          : _ProductsList(state: state),
                },
              ),
            ),
            BlocSelector<ProductsBoardBloc, ProductsBoardState, Set<String>>(
              selector: (s) => s.selected,
              builder: (context, selected) =>
                  selected.isEmpty ? const SizedBox.shrink() : const _BulkActionBar(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Filters
// ─────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatefulWidget {
  const _FilterBar();

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  final _searchCtrl = TextEditingController();
  late final Future<List<Category>> _taxonomyFuture = sl<GetTaxonomy>()();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final bloc = context.read<ProductsBoardBloc>();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 44,
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.productsBoardSearchLabel,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    bloc.add(const ProductsBoardSearchChanged(''));
                  },
                ),
                border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
              ),
              onChanged: (v) => bloc.add(ProductsBoardSearchChanged(v)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          BlocBuilder<ProductsBoardBloc, ProductsBoardState>(
            buildWhen: (a, b) =>
                a.shops != b.shops ||
                a.shopId != b.shopId ||
                a.category != b.category ||
                a.stockStatus != b.stockStatus ||
                a.isPromo != b.isPromo ||
                a.deletedOnly != b.deletedOnly,
            builder: (context, state) => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ShopDropdown(state: state, bloc: bloc, isArabic: isArabic),
                FutureBuilder<List<Category>>(
                  future: _taxonomyFuture,
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? const <Category>[];
                    return _CategoryDropdown(
                      state: state,
                      bloc: bloc,
                      isArabic: isArabic,
                      categories: categories,
                    );
                  },
                ),
                _StockDropdown(state: state, bloc: bloc),
                _PromoChip(state: state, bloc: bloc),
                _DeletedChip(state: state, bloc: bloc),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopDropdown extends StatelessWidget {
  const _ShopDropdown({required this.state, required this.bloc, required this.isArabic});

  final ProductsBoardState state;
  final ProductsBoardBloc bloc;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String?>(
        initialValue: state.shopId,
        isDense: true,
        decoration: InputDecoration(
          isDense: true,
          labelText: l10n.productsBoardFilterShop,
          border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
        ),
        items: [
          DropdownMenuItem(value: null, child: Text(l10n.shopsFilterAll)),
          for (final shop in state.shops)
            DropdownMenuItem(
              value: shop.id,
              child: Text(
                isArabic ? shop.nameAr : shop.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (v) => bloc.add(ProductsBoardFilterChanged(
          shopId: v,
          category: state.category,
          stockStatus: state.stockStatus,
          isPromo: state.isPromo,
          deletedOnly: state.deletedOnly,
        )),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.state,
    required this.bloc,
    required this.isArabic,
    required this.categories,
  });

  final ProductsBoardState state;
  final ProductsBoardBloc bloc;
  final bool isArabic;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String?>(
        initialValue: state.category,
        isDense: true,
        decoration: InputDecoration(
          isDense: true,
          labelText: l10n.fieldProductCategory,
          border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
        ),
        items: [
          DropdownMenuItem(value: null, child: Text(l10n.shopsFilterAll)),
          for (final c in categories)
            DropdownMenuItem(
              value: c.id,
              child: Text(isArabic ? c.nameAr : c.nameEn, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (v) => bloc.add(ProductsBoardFilterChanged(
          shopId: state.shopId,
          category: v,
          stockStatus: state.stockStatus,
          isPromo: state.isPromo,
          deletedOnly: state.deletedOnly,
        )),
      ),
    );
  }
}

class _StockDropdown extends StatelessWidget {
  const _StockDropdown({required this.state, required this.bloc});

  final ProductsBoardState state;
  final ProductsBoardBloc bloc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: 140,
      child: DropdownButtonFormField<String?>(
        initialValue: state.stockStatus,
        isDense: true,
        decoration: InputDecoration(
          isDense: true,
          labelText: l10n.fieldProductStock,
          border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
        ),
        items: [
          DropdownMenuItem(value: null, child: Text(l10n.shopsFilterAll)),
          for (final s in StockStatus.values)
            DropdownMenuItem(value: s.wire, child: Text(_stockLabel(l10n, s))),
        ],
        onChanged: (v) => bloc.add(ProductsBoardFilterChanged(
          shopId: state.shopId,
          category: state.category,
          stockStatus: v,
          isPromo: state.isPromo,
          deletedOnly: state.deletedOnly,
        )),
      ),
    );
  }
}

class _PromoChip extends StatelessWidget {
  const _PromoChip({required this.state, required this.bloc});

  final ProductsBoardState state;
  final ProductsBoardBloc bloc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FilterChip(
      label: Text(l10n.fieldProductPromoLabel),
      selected: state.isPromo == true,
      onSelected: (selected) => bloc.add(ProductsBoardFilterChanged(
        shopId: state.shopId,
        category: state.category,
        stockStatus: state.stockStatus,
        isPromo: selected ? true : null,
        deletedOnly: state.deletedOnly,
      )),
    );
  }
}

class _DeletedChip extends StatelessWidget {
  const _DeletedChip({required this.state, required this.bloc});

  final ProductsBoardState state;
  final ProductsBoardBloc bloc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FilterChip(
      label: Text(l10n.productsBoardDeletedOnly),
      selected: state.deletedOnly,
      onSelected: (selected) => bloc.add(ProductsBoardFilterChanged(
        shopId: state.shopId,
        category: state.category,
        stockStatus: state.stockStatus,
        isPromo: state.isPromo,
        deletedOnly: selected,
      )),
    );
  }
}

String _stockLabel(AppLocalizations l10n, StockStatus status) => switch (status) {
      StockStatus.inStock => l10n.productStockIn,
      StockStatus.lowStock => l10n.productStockLow,
      StockStatus.outOfStock => l10n.productStockOut,
    };

// ─────────────────────────────────────────────────────────────────────────
// List + rows
// ─────────────────────────────────────────────────────────────────────────

class _ProductsList extends StatelessWidget {
  const _ProductsList({required this.state});

  final ProductsBoardState state;

  @override
  Widget build(BuildContext context) {
    final products = state.visibleProducts;
    final showFooter = state.hasMore && !state.isSearching;
    final shopsById = {for (final s in state.shops) s.id: s};

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 320) {
          context.read<ProductsBoardBloc>().add(const ProductsBoardLoadMoreRequested());
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        itemCount: products.length + (showFooter ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          if (i >= products.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: OutlinedButton(
                  onPressed: () => context
                      .read<ProductsBoardBloc>()
                      .add(const ProductsBoardLoadMoreRequested()),
                  child: Text(AppLocalizations.of(context)!.auditLoadMore),
                ),
              ),
            );
          }
          final product = products[i];
          return _ProductRow(
            product: product,
            shop: shopsById[product.shopId],
            selectionMode: state.selected.isNotEmpty,
            selected: state.selected.contains(product.id),
          );
        },
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.shop,
    required this.selectionMode,
    required this.selected,
  });

  final Product product;
  final Shop? shop;
  final bool selectionMode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final bloc = context.read<ProductsBoardBloc>();

    return GestureDetector(
      onLongPress: () => bloc.add(ProductSelectionToggled(product.id)),
      child: AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: selectionMode
          ? () => bloc.add(ProductSelectionToggled(product.id))
          : () => _openEdit(context, bloc),
      child: Row(
        children: [
          if (selectionMode) ...[
            Checkbox(
              value: selected,
              onChanged: (_) => bloc.add(ProductSelectionToggled(product.id)),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          ShimmerImage(url: product.imageUrl, width: 48, height: 48, radius: AppRadius.mdAll),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic ? product.nameAr : product.name,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: product.deleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  shop == null ? product.shopId : (isArabic ? shop!.nameAr : shop!.name),
                  style: text.bodySmall?.copyWith(color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    PriceTagText(product.priceMinor),
                    StatusChip(
                      label: _stockLabel(l10n, product.stockStatus),
                      tone: product.stockStatus == StockStatus.inStock
                          ? StatusTone.positive
                          : StatusTone.caution,
                    ),
                    if (product.isPromo)
                      StatusChip(label: l10n.fieldProductPromoLabel, tone: StatusTone.neutral),
                    if (product.isFeatured)
                      StatusChip(label: l10n.shopsFeaturedBadge, tone: StatusTone.neutral),
                    if (product.deleted)
                      StatusChip(label: l10n.productsBoardDeletedOnly, tone: StatusTone.caution),
                  ],
                ),
              ],
            ),
          ),
          if (!selectionMode) _RowMenu(product: product),
        ],
      ),
      ),
    );
  }

  void _openEdit(BuildContext context, ProductsBoardBloc bloc) async {
    final result = await context.push<bool>(
      '/catalog/product-form',
      extra: ProductFormArgs(shopId: product.shopId, product: product),
    );
    if (result == true) {
      bloc.add(const ProductsBoardRetryRequested());
    }
  }
}

/// Minimal inline price text (the shared `PriceTag` defaults to a bigger
/// style than fits this row's badge row).
class PriceTagText extends StatelessWidget {
  const PriceTagText(this.minor, {super.key});

  final int minor;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Text(
      Money.format(minor, languageCode: locale),
      style: text.bodySmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<ProductsBoardBloc>();
    final admin = context.read<AuthBloc>().state.adminProfile;
    final actorUid = context.read<AuthBloc>().state.user?.uid ?? '';
    final canHardDelete = product.deleted && (admin?.can(Permissions.all) ?? false);

    return PopupMenuButton<String>(
      onSelected: (action) async {
        switch (action) {
          case 'duplicate':
            bloc.add(ProductsBoardDuplicateRequested(product.id));
          case 'softDelete':
            final confirmed = await _confirm(context, l10n.productsBoardConfirmSoftDelete);
            if (confirmed) {
              bloc.add(ProductsBoardSoftDeleteRequested(product.id, actorUid));
            }
          case 'restore':
            bloc.add(ProductsBoardRestoreRequested(product.id));
          case 'hardDelete':
            final typed = await _typeToConfirm(context, product.name);
            if (typed) bloc.add(ProductsBoardHardDeleteRequested(product.id));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'duplicate', child: Text(l10n.productsBoardDuplicate)),
        if (!product.deleted)
          PopupMenuItem(value: 'softDelete', child: Text(l10n.productsBoardSoftDelete))
        else
          PopupMenuItem(value: 'restore', child: Text(l10n.productsBoardRestore)),
        if (canHardDelete)
          PopupMenuItem(
            value: 'hardDelete',
            child: Text(l10n.productsBoardHardDelete, style: const TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Future<bool> _confirm(BuildContext context, String body) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<bool> _typeToConfirm(BuildContext context, String name) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(l10n.productsBoardHardDelete),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.productsBoardHardDeleteWarning(name)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(labelText: l10n.productsBoardTypeNameLabel),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: ctrl.text.trim() == name
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
              child: Text(l10n.actionConfirm),
            ),
          ],
        ),
      ),
    );
    return confirmed == true;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Bulk action bar + dialogs
// ─────────────────────────────────────────────────────────────────────────

class _BulkActionBar extends StatelessWidget {
  const _BulkActionBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<ProductsBoardBloc>();
    final count = context.select((ProductsBoardBloc b) => b.state.selected.length);
    final busy = context.select((ProductsBoardBloc b) => b.state.bulkBusy);

    return Material(
      color: scheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(child: Text(l10n.productsBoardSelectedCount(count))),
              if (busy)
                const Padding(
                  padding: EdgeInsetsDirectional.only(end: AppSpacing.md),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4)),
                ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => bloc.add(const ProductsBoardSelectionCleared()),
                child: Text(l10n.actionCancel),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: busy ? null : () => _openBulkMenu(context, bloc),
                icon: const Icon(Icons.playlist_add_check, size: 18),
                label: Text(l10n.productsBoardBulkAction),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBulkMenu(BuildContext context, ProductsBoardBloc bloc) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: Text(l10n.productsBoardBulkPrice),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _bulkPriceDialog(context, bloc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(l10n.productsBoardBulkStock),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _bulkStockDialog(context, bloc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_offer_outlined),
              title: Text(l10n.productsBoardBulkPromo),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _bulkBoolDialog(
                  context,
                  title: l10n.productsBoardBulkPromo,
                  onConfirm: (v) => bloc.add(ProductsBoardBulkPromoRequested(v)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text(l10n.shopsFeaturedBadge),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _bulkBoolDialog(
                  context,
                  title: l10n.shopsFeaturedBadge,
                  onConfirm: (v) => bloc.add(ProductsBoardBulkFeaturedRequested(v)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: Text(l10n.productsBoardBulkCategory),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _bulkCategoryDialog(context, bloc);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bulkPriceDialog(BuildContext context, ProductsBoardBloc bloc) async {
    final l10n = AppLocalizations.of(context)!;
    var isPercent = true;
    var isIncrease = true;
    final ctrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final parsed = double.tryParse(ctrl.text.trim());
          return AlertDialog(
            title: Text(l10n.productsBoardBulkPrice),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text(l10n.productsBoardBulkPricePercent)),
                    ButtonSegment(value: false, label: Text(l10n.productsBoardBulkPriceFixed)),
                  ],
                  selected: {isPercent},
                  onSelectionChanged: (v) => setState(() => isPercent = v.first),
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text(l10n.productsBoardBulkPriceIncrease)),
                    ButtonSegment(value: false, label: Text(l10n.productsBoardBulkPriceDecrease)),
                  ],
                  selected: {isIncrease},
                  onSelectionChanged: (v) => setState(() => isIncrease = v.first),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: isPercent
                        ? l10n.productsBoardBulkPricePercentLabel
                        : l10n.productsBoardBulkPriceFixedLabel,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                onPressed: parsed == null || parsed <= 0
                    ? null
                    : () {
                        final signed = isIncrease ? parsed : -parsed;
                        if (isPercent) {
                          bloc.add(ProductsBoardBulkPriceRequested(
                            percentBps: (signed * 100).round(),
                          ));
                        } else {
                          final minor = (signed * 100).round();
                          bloc.add(ProductsBoardBulkPriceRequested(fixedDeltaMinor: minor));
                        }
                        Navigator.of(dialogContext).pop();
                      },
                child: Text(l10n.actionConfirm),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _bulkStockDialog(BuildContext context, ProductsBoardBloc bloc) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.productsBoardBulkStock),
        children: [
          for (final status in StockStatus.values)
            SimpleDialogOption(
              onPressed: () {
                bloc.add(ProductsBoardBulkStockRequested(status));
                Navigator.of(dialogContext).pop();
              },
              child: Text(_stockLabel(l10n, status)),
            ),
        ],
      ),
    );
  }

  Future<void> _bulkBoolDialog(
    BuildContext context, {
    required String title,
    required void Function(bool value) onConfirm,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(title),
        children: [
          SimpleDialogOption(
            onPressed: () {
              onConfirm(true);
              Navigator.of(dialogContext).pop();
            },
            child: Text(l10n.actionEnable),
          ),
          SimpleDialogOption(
            onPressed: () {
              onConfirm(false);
              Navigator.of(dialogContext).pop();
            },
            child: Text(l10n.actionDisable),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkCategoryDialog(BuildContext context, ProductsBoardBloc bloc) async {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final taxonomyFuture = sl<GetTaxonomy>()();
    String? categoryId;
    String? subcategoryId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(l10n.productsBoardBulkCategory),
          content: FutureBuilder<List<Category>>(
            future: taxonomyFuture,
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const <Category>[];
              Category? selected;
              for (final c in categories) {
                if (c.id == categoryId) selected = c;
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: categoryId,
                    decoration: InputDecoration(labelText: l10n.fieldProductCategory),
                    items: [
                      for (final c in categories)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(isArabic ? c.nameAr : c.nameEn),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      categoryId = v;
                      subcategoryId = null;
                    }),
                  ),
                  DropdownButtonFormField<String>(
                    key: ValueKey(categoryId),
                    initialValue: subcategoryId,
                    decoration: InputDecoration(labelText: l10n.fieldProductSubcategory),
                    items: [
                      for (final s in selected?.subcategories ?? const [])
                        DropdownMenuItem(
                          value: s.id,
                          child: Text(isArabic ? s.nameAr : s.nameEn),
                        ),
                    ],
                    onChanged: selected == null
                        ? null
                        : (v) => setState(() => subcategoryId = v),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: categoryId == null || subcategoryId == null
                  ? null
                  : () {
                      bloc.add(ProductsBoardBulkCategoryRequested(
                        category: categoryId!,
                        subcategoryId: subcategoryId!,
                      ));
                      Navigator.of(dialogContext).pop();
                    },
              child: Text(l10n.actionConfirm),
            ),
          ],
        ),
      ),
    );
  }
}
