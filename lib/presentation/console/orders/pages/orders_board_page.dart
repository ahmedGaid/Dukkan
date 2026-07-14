import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/areas/entities/area.dart';
import '../../../../domain/order/entities/order.dart';
import '../../../../domain/order/entities/order_status.dart';
import '../../../../domain/shop/entities/shop.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orders/order_status_view.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/price_tag.dart';
import '../../../widgets/common/skeletons.dart';
import '../../../widgets/common/status_chip.dart';
import '../bloc/orders_board_bloc.dart';

/// The Founder Console order board (`/console/orders`, FC10). Status filter
/// chips (the server facet), shop/area dropdowns + a date range (client-side
/// refine over the loaded pages), and an exact order-id/phone search. Row tap
/// opens the shared order detail page in the staff view.
class OrdersBoardPage extends StatelessWidget {
  const OrdersBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final initialStatus = GoRouterState.of(context).uri.queryParameters['status'];
    return BlocProvider(
      create: (_) =>
          sl<OrdersBoardBloc>()..add(OrdersBoardStarted(initialStatus: initialStatus)),
      child: const _OrdersBoardView(),
    );
  }
}

class _OrdersBoardView extends StatelessWidget {
  const _OrdersBoardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          const _FilterBar(),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: BlocBuilder<OrdersBoardBloc, OrdersBoardState>(
              builder: (context, state) => switch (state.status) {
                OrdersBoardStatus.loading => const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: ListShimmer(),
                  ),
                OrdersBoardStatus.error => EmptyState(
                    icon: Icons.error_outline,
                    title: l10n.errorTitle,
                    message: l10n.ordersBoardErrorBody,
                    actionLabel: l10n.actionRetry,
                    onAction: () =>
                        context.read<OrdersBoardBloc>().add(const OrdersBoardRetryRequested()),
                  ),
                OrdersBoardStatus.loaded => state.filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: l10n.ordersBoardEmptyTitle,
                        message: l10n.ordersBoardEmptyBody,
                      )
                    : _OrdersList(state: state),
              },
            ),
          ),
        ],
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(BuildContext context, OrdersBoardState state) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: state.dateFrom != null && state.dateTo != null
          ? DateTimeRange(start: state.dateFrom!, end: state.dateTo!)
          : null,
    );
    if (range != null && context.mounted) {
      context.read<OrdersBoardBloc>().add(OrdersBoardDateRangeChanged(
            from: range.start,
            to: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                labelText: l10n.ordersBoardSearchLabel,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    context.read<OrdersBoardBloc>().add(const OrdersBoardSearchCleared());
                  },
                ),
                border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
              ),
              onSubmitted: (v) =>
                  context.read<OrdersBoardBloc>().add(OrdersBoardSearchSubmitted(v)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          BlocSelector<OrdersBoardBloc, OrdersBoardState, String?>(
            selector: (s) => s.statusFilter,
            builder: (context, statusFilter) => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _StatusChoiceChip(label: l10n.shopsFilterAll, value: null, selected: statusFilter),
                for (final status in OrderStatus.values)
                  _StatusChoiceChip(
                    label: orderStatusView(l10n, status).label,
                    value: status.wire,
                    selected: statusFilter,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          BlocBuilder<OrdersBoardBloc, OrdersBoardState>(
            buildWhen: (a, b) =>
                a.shops != b.shops ||
                a.areas != b.areas ||
                a.shopFilter != b.shopFilter ||
                a.areaFilter != b.areaFilter ||
                a.dateFrom != b.dateFrom ||
                a.dateTo != b.dateTo,
            builder: (context, state) {
              final isArabic = Localizations.localeOf(context).languageCode == 'ar';
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String?>(
                      initialValue: state.shopFilter,
                      isDense: true,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: l10n.ordersBoardShopLabel,
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
                      onChanged: (v) =>
                          context.read<OrdersBoardBloc>().add(OrdersBoardShopFilterChanged(v)),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String?>(
                      initialValue: state.areaFilter,
                      isDense: true,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: l10n.ordersBoardAreaLabel,
                        border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(l10n.shopsFilterAll)),
                        for (final area in state.areas)
                          DropdownMenuItem(
                            value: area.id,
                            child: Text(
                              isArabic ? area.nameAr : area.nameEn,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) =>
                          context.read<OrdersBoardBloc>().add(OrdersBoardAreaFilterChanged(v)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickDateRange(context, state),
                    icon: const Icon(Icons.date_range_outlined, size: 18),
                    label: Text(
                      state.dateFrom == null
                          ? l10n.ordersBoardDateRangeLabel
                          : '${DateFormat.Md().format(state.dateFrom!)}'
                              ' – ${DateFormat.Md().format(state.dateTo!)}',
                    ),
                  ),
                  if (state.dateFrom != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => context
                          .read<OrdersBoardBloc>()
                          .add(const OrdersBoardDateRangeChanged()),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusChoiceChip extends StatelessWidget {
  const _StatusChoiceChip({required this.label, required this.value, required this.selected});

  final String label;
  final String? value;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) =>
          context.read<OrdersBoardBloc>().add(OrdersBoardStatusFilterChanged(value)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// List + rows
// ─────────────────────────────────────────────────────────────────────────

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.state});

  final OrdersBoardState state;

  @override
  Widget build(BuildContext context) {
    final orders = state.filtered;
    // Search results aren't server-paginated — no footer for them.
    final showFooter = state.searchResults == null && state.hasMore;
    final areaNames = {for (final a in state.areas) a.id: a};
    final shopNames = {for (final s in state.shops) s.id: s};

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 320) {
          context.read<OrdersBoardBloc>().add(const OrdersBoardLoadMoreRequested());
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: orders.length + (showFooter ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          if (i >= orders.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: OutlinedButton(
                  onPressed: () =>
                      context.read<OrdersBoardBloc>().add(const OrdersBoardLoadMoreRequested()),
                  child: Text(AppLocalizations.of(context)!.auditLoadMore),
                ),
              ),
            );
          }
          return _OrderRow(
            order: orders[i],
            shopName: shopNames[orders[i].shopId],
            areaName: areaNames[orders[i].deliveryAddress.areaId],
          );
        },
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.shopName, required this.areaName});

  final Order order;
  final Shop? shopName;
  final Area? areaName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final isArabic = locale == 'ar';
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final view = orderStatusView(l10n, order.status);
    final shop = shopName;
    final area = areaName;
    final shopLabel = shop == null ? order.shopId : (isArabic ? shop.nameAr : shop.name);
    final areaLabel = area == null ? null : (isArabic ? area.nameAr : area.nameEn);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push('/order/${order.id}?role=staff'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  areaLabel == null ? shopLabel : '$shopLabel · $areaLabel',
                  style: text.bodySmall?.copyWith(color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusChip(label: view.label, tone: view.tone),
                    StatusChip(label: order.driverName ?? l10n.ordersBoardNoDriver),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              PriceTag(order.totalMinor),
              const SizedBox(height: AppSpacing.xs),
              Text(
                DateFormat.Md(locale).add_Hm().format(order.createdAt),
                style: text.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
