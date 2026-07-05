import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/notifications/repositories/notification_repository.dart';
import '../../../domain/notifications/usecases/notify_order_event.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/order/entities/order_status.dart';
import '../../../domain/order/usecases/update_order_status.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/price_tag.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/common/status_chip.dart';
import '../bloc/owner_orders_bloc.dart';
import '../order_status_view.dart';

/// The owner's order desk (S3): incoming orders for their own shop,
/// realtime, newest first. A sibling entry point to the catalog manager
/// (S2) — reached via `OwnerHomeShell`'s second tab, same page structure as
/// the customer `OrdersPage` (plain title, no AppBar).
class OrderDeskPage extends StatelessWidget {
  const OrderDeskPage({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<OwnerOrdersBloc>(param1: shopId)..add(const OwnerOrdersStarted()),
      child: const _OrderDeskView(),
    );
  }
}

class _OrderDeskView extends StatelessWidget {
  const _OrderDeskView();

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
              child: Text(l10n.orderDeskTitle, style: text.headlineSmall),
            ),
            Expanded(
              child: BlocBuilder<OwnerOrdersBloc, OwnerOrdersState>(
                builder: (context, state) => switch (state.status) {
                  OwnerOrdersStatus.loading => const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: ListShimmer(),
                    ),
                  OwnerOrdersStatus.error => EmptyState(
                      icon: Icons.error_outline,
                      title: l10n.errorTitle,
                      message: l10n.orderDeskErrorBody,
                      actionLabel: l10n.actionRetry,
                      onAction: () => context
                          .read<OwnerOrdersBloc>()
                          .add(const OwnerOrdersRetryRequested()),
                    ),
                  OwnerOrdersStatus.loaded => state.orders.isEmpty
                      ? EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: l10n.orderDeskEmptyTitle,
                          message: l10n.orderDeskEmptyBody,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: state.orders.length + 1,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) => i == 0
                              ? _DailySummaryStrip(orders: state.orders)
                              : _OwnerOrderCard(order: state.orders[i - 1]),
                        ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailySummaryStrip extends StatelessWidget {
  const _DailySummaryStrip({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = orders.where(
      (o) =>
          o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day,
    );
    final totalMinor = today.fold(0, (sum, o) => sum + o.totalMinor);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.today_outlined, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.orderDeskTodayLabel, style: text.bodySmall),
                Text(
                  '${today.length}',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          PriceTag(
            totalMinor,
            style: text.titleMedium
                ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _OwnerOrderCard extends StatefulWidget {
  const _OwnerOrderCard({required this.order});

  final Order order;

  @override
  State<_OwnerOrderCard> createState() => _OwnerOrderCardState();
}

class _OwnerOrderCardState extends State<_OwnerOrderCard> {
  bool _submitting = false;

  Future<void> _apply(OrderStatus target) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await sl<UpdateOrderStatus>()(widget.order.id, target);
      _notifyCustomer(target);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        AppLocalizations.of(context)!.orderActionErrorBody,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Fire-and-forget push to the customer. Push text is decided at send time
  /// and we don't track each user's language, so every push is bilingual —
  /// see `NotificationRemoteDataSource` doc.
  void _notifyCustomer(OrderStatus target) {
    final lAr = lookupAppLocalizations(const Locale('ar'));
    final lEn = lookupAppLocalizations(const Locale('en'));
    final statusAr = orderStatusView(lAr, target).label;
    final statusEn = orderStatusView(lEn, target).label;
    unawaited(sl<NotifyOrderEvent>()(
      orderId: widget.order.id,
      type: NotificationEventType.statusUpdate,
      title: '${lAr.notifyOrderStatusTitle} / ${lEn.notifyOrderStatusTitle}',
      body: '${lAr.notifyOrderStatusBody(statusAr)} / '
          '${lEn.notifyOrderStatusBody(statusEn)}',
    ));
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.orderRejectConfirmTitle),
        content: Text(l10n.orderRejectConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionRejectOrder),
          ),
        ],
      ),
    );
    if (confirmed == true) _apply(OrderStatus.rejected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final order = widget.order;
    final view = orderStatusView(l10n, order.status);
    final primary = orderPrimaryAction(l10n, order.status);
    final secondary = orderSecondaryAction(l10n, order.status);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusChip(label: view.label, tone: view.tone),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      DateFormat.yMMMd(locale)
                          .add_Hm()
                          .format(order.createdAt),
                      style: text.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 16,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text('${order.items.length}', style: text.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              PriceTag(
                order.totalMinor,
                style: text.titleMedium
                    ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (primary != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (secondary != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _submitting ? null : () => _reject(),
                      child: Text(secondary.label),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _submitting ? null : () => _apply(primary.target),
                    child: Text(primary.label),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
