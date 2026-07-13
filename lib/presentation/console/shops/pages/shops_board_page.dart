import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/shop/entities/shop.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/shimmer_image.dart';
import '../../../widgets/common/skeletons.dart';
import '../../../widgets/common/status_chip.dart';
import '../bloc/shops_board_bloc.dart';

/// The Founder Console shop management board (`/console/shops`, FC7). Status
/// filter chips, an Arabic-folded name search over the already-loaded list,
/// and a client-paginated list (the shop count is small — see
/// `ShopsBoardBloc` doc). Row tap opens the detail page with the tapped
/// [Shop] as `extra` (mirrors `UsersListPage`).
class ShopsBoardPage extends StatelessWidget {
  const ShopsBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ShopsBoardBloc>()..add(const ShopsBoardStarted()),
      child: const _ShopsBoardView(),
    );
  }
}

class _ShopsBoardView extends StatelessWidget {
  const _ShopsBoardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          const _SearchAndFilterBar(),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: BlocBuilder<ShopsBoardBloc, ShopsBoardState>(
              buildWhen: (a, b) =>
                  a.status != b.status || a.visible != b.visible || a.hasMore != b.hasMore,
              builder: (context, state) => switch (state.status) {
                ShopsBoardStatus.loading => const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: ListShimmer(),
                  ),
                ShopsBoardStatus.error => EmptyState(
                    icon: Icons.error_outline,
                    title: l10n.errorTitle,
                    message: l10n.shopsBoardErrorBody,
                    actionLabel: l10n.actionRetry,
                    onAction: () =>
                        context.read<ShopsBoardBloc>().add(const ShopsBoardRetryRequested()),
                  ),
                ShopsBoardStatus.loaded => state.visible.isEmpty
                    ? EmptyState(
                        icon: Icons.storefront_outlined,
                        title: l10n.shopsBoardEmptyTitle,
                        message: l10n.shopsBoardEmptyBody,
                      )
                    : _ShopsList(state: state),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Search + filters
// ─────────────────────────────────────────────────────────────────────────

class _SearchAndFilterBar extends StatefulWidget {
  const _SearchAndFilterBar();

  @override
  State<_SearchAndFilterBar> createState() => _SearchAndFilterBarState();
}

class _SearchAndFilterBarState extends State<_SearchAndFilterBar> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: l10n.shopsBoardSearchLabel,
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<ShopsBoardBloc>().add(const ShopsBoardSearchChanged(''));
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
                    ),
                    onChanged: (v) =>
                        context.read<ShopsBoardBloc>().add(ShopsBoardSearchChanged(v)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => context.push('/console/shops/new'),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.shopsBoardCreateAction),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          BlocSelector<ShopsBoardBloc, ShopsBoardState, String?>(
            selector: (s) => s.statusFilter,
            builder: (context, statusFilter) => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _FilterChip(
                  label: l10n.shopsFilterAll,
                  selected: statusFilter == null,
                  onTap: () => context
                      .read<ShopsBoardBloc>()
                      .add(const ShopsBoardStatusFilterChanged(null)),
                ),
                _FilterChip(
                  label: l10n.shopsStatusPending,
                  selected: statusFilter == 'pending',
                  onTap: () => context
                      .read<ShopsBoardBloc>()
                      .add(const ShopsBoardStatusFilterChanged('pending')),
                ),
                _FilterChip(
                  label: l10n.shopsStatusActive,
                  selected: statusFilter == 'active',
                  onTap: () => context
                      .read<ShopsBoardBloc>()
                      .add(const ShopsBoardStatusFilterChanged('active')),
                ),
                _FilterChip(
                  label: l10n.shopsStatusSuspended,
                  selected: statusFilter == 'suspended',
                  onTap: () => context
                      .read<ShopsBoardBloc>()
                      .add(const ShopsBoardStatusFilterChanged('suspended')),
                ),
                _FilterChip(
                  label: l10n.shopsStatusDeleted,
                  selected: statusFilter == 'deleted',
                  onTap: () => context
                      .read<ShopsBoardBloc>()
                      .add(const ShopsBoardStatusFilterChanged('deleted')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}

// ─────────────────────────────────────────────────────────────────────────
// List + rows
// ─────────────────────────────────────────────────────────────────────────

class _ShopsList extends StatelessWidget {
  const _ShopsList({required this.state});

  final ShopsBoardState state;

  @override
  Widget build(BuildContext context) {
    final shops = state.visible;
    final showFooter = state.hasMore;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 320) {
          context.read<ShopsBoardBloc>().add(const ShopsBoardLoadMoreRequested());
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: shops.length + (showFooter ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          if (i >= shops.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: OutlinedButton(
                  onPressed: () =>
                      context.read<ShopsBoardBloc>().add(const ShopsBoardLoadMoreRequested()),
                  child: Text(AppLocalizations.of(context)!.auditLoadMore),
                ),
              ),
            );
          }
          return _ShopRow(shop: shops[i]);
        },
      ),
    );
  }
}

class _ShopRow extends StatelessWidget {
  const _ShopRow({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final muted = scheme.onSurface.withValues(alpha: 0.6);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push('/console/shops/${shop.id}', extra: shop),
      child: Row(
        children: [
          ShimmerImage(url: shop.logoUrl, width: 48, height: 48, radius: AppRadius.mdAll),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic ? shop.nameAr : shop.name,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: shop.deleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.shopsBoardOwnerLabel(shop.ownerUid),
                  style: text.bodySmall?.copyWith(color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusChip(label: _statusLabel(l10n, shop.status), tone: _statusTone(shop.status)),
                    if (shop.deleted)
                      StatusChip(label: l10n.shopsStatusDeleted, tone: StatusTone.caution),
                    if (shop.isFeatured)
                      StatusChip(label: l10n.shopsFeaturedBadge, tone: StatusTone.neutral),
                    if (shop.isVerified)
                      StatusChip(label: l10n.shopsVerifiedBadge, tone: StatusTone.neutral),
                    if (shop.averageRating != null)
                      StatusChip(label: shop.averageRating!.toStringAsFixed(1)),
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

String _statusLabel(AppLocalizations l10n, String status) => switch (status) {
      'pending' => l10n.shopsStatusPending,
      'suspended' => l10n.shopsStatusSuspended,
      _ => l10n.shopsStatusActive,
    };

StatusTone _statusTone(String status) => switch (status) {
      'pending' => StatusTone.caution,
      'suspended' => StatusTone.caution,
      _ => StatusTone.positive,
    };
