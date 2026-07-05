import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/order/entities/order_item.dart';
import '../../../domain/order/entities/order_status.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/price_tag.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/common/status_chip.dart';
import '../bloc/order_detail_bloc.dart';
import '../order_status_view.dart';
import '../widgets/order_status_stepper.dart';

/// One order's tracking page — realtime status stepper, items, delivery
/// address, and a cancel action while `isCancellable`. Owns its
/// [OrderDetailBloc] (order id is the factory param).
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderDetailBloc>(param1: orderId)
        ..add(const OrderDetailStarted()),
      child: const _OrderDetailView(),
    );
  }
}

class _OrderDetailView extends StatelessWidget {
  const _OrderDetailView();

  Future<void> _confirmCancel(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.orderCancelConfirmTitle),
        content: Text(l10n.orderCancelConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionCancelOrder),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<OrderDetailBloc>().add(const OrderDetailCancelRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderDetailTitle)),
      body: BlocConsumer<OrderDetailBloc, OrderDetailState>(
        listenWhen: (previous, current) =>
            previous.cancelStatus != current.cancelStatus,
        listener: (context, state) {
          if (state.cancelStatus == OrderCancelStatus.failure) {
            AppSnackBar.error(context, l10n.orderCancelErrorBody);
          }
        },
        builder: (context, state) => switch (state.status) {
          OrderDetailStatus.loading => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: ListShimmer(count: 3, itemHeight: 64),
            ),
          OrderDetailStatus.error => EmptyState(
              icon: Icons.error_outline,
              title: l10n.errorTitle,
              message: l10n.ordersErrorBody,
            ),
          OrderDetailStatus.loaded => _OrderDetailContent(
              order: state.order!,
              isCancelling: state.isCancelling,
              onCancel: () => _confirmCancel(context),
            ),
        },
      ),
    );
  }
}

class _OrderDetailContent extends StatelessWidget {
  const _OrderDetailContent({
    required this.order,
    required this.isCancelling,
    required this.onCancel,
  });

  final Order order;
  final bool isCancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final view = orderStatusView(l10n, order.status);
    final isTerminalBranch =
        order.status == OrderStatus.cancelled || order.status == OrderStatus.rejected;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              Text(
                DateFormat.yMMMd(locale).add_Hm().format(order.createdAt),
                style: text.bodySmall
                    ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: AppSpacing.md),
              if (isTerminalBranch)
                StatusChip(label: view.label, tone: view.tone)
              else
                OrderStatusStepper(status: order.status),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.checkoutSummary, style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              _ItemsCard(items: order.items, totalMinor: order.totalMinor),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.checkoutAddressSection, style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              _AddressCard(order: order),
            ],
          ),
        ),
        if (order.status.isCancellable)
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: scheme.outline)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: OutlinedButton(
                  onPressed: isCancelling ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(color: scheme.error),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                  ),
                  child: isCancelling
                      ? SizedBox(
                          width: AppSpacing.lg,
                          height: AppSpacing.lg,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(scheme.error),
                          ),
                        )
                      : Text(l10n.actionCancelOrder),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.items, required this.totalMinor});

  final List<OrderItem> items;
  final int totalMinor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration:
          BoxDecoration(color: scheme.surface, borderRadius: AppRadius.lgAll),
      child: Column(
        children: [
          for (final item in items) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${isArabic ? item.nameAr : item.name} × ${item.quantity}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium,
                  ),
                ),
                PriceTag(item.subtotalMinor),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const Divider(),
          Row(
            children: [
              Expanded(child: Text(l10n.cartTotal, style: text.titleSmall)),
              PriceTag(
                totalMinor,
                style: text.titleMedium
                    ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 16,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.codLabel,
                style: text.bodySmall
                    ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final address = order.deliveryAddress;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration:
          BoxDecoration(color: scheme.surface, borderRadius: AppRadius.lgAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 20,
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${address.line1}، ${address.city}', style: text.bodyMedium),
                if (address.notes != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    address.notes!,
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
