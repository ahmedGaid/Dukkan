import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/areas/entities/area.dart';
import '../../../domain/auth/entities/app_user.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/order/entities/order_item.dart';
import '../../../domain/order/entities/order_status.dart';
import '../../../domain/order/entities/status_change.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/price_tag.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/common/status_chip.dart';
import '../bloc/order_detail_bloc.dart';
import '../order_status_view.dart';
import '../order_viewer_role.dart';
import '../widgets/assign_driver_sheet.dart';
import '../widgets/order_status_stepper.dart';
import '../widgets/star_rating_picker.dart';

/// One order's tracking page — realtime status stepper, items, delivery
/// address, and a cancel action while `isCancellable`. Reused for the owner
/// order-desk (M2) and the courier detail view (M10): [role] gates the
/// customer/payment/fee/driver/advance blocks, and the bloc additionally
/// resolves the customer's `/users` profile (owner+courier) and the delivery
/// area's name (courier). Owns its [OrderDetailBloc] (order id + role are the
/// factory params).
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
    this.role = OrderViewerRole.customer,
  });

  final String orderId;
  final OrderViewerRole role;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderDetailBloc>(param1: orderId, param2: role)
        ..add(const OrderDetailStarted()),
      child: _OrderDetailView(role: role),
    );
  }
}

class _OrderDetailView extends StatelessWidget {
  const _OrderDetailView({required this.role});

  final OrderViewerRole role;

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

  /// Only the final `delivered` step confirms — "picked up" is a single tap
  /// (plan: `FILE_10_COURIER_SHELL.md` Task C).
  Future<void> _handleCourierAction(
    BuildContext context,
    OrderStatus target,
  ) async {
    if (target == OrderStatus.delivered) {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.courierActionDeliveredConfirmTitle),
          content: Text(l10n.courierActionDeliveredConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.courierActionDelivered),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    context.read<OrderDetailBloc>().add(OrderDetailAdvanceRequested(target));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderDetailTitle)),
      body: BlocConsumer<OrderDetailBloc, OrderDetailState>(
        listenWhen: (previous, current) =>
            previous.cancelStatus != current.cancelStatus ||
            previous.rateStatus != current.rateStatus ||
            previous.advanceStatus != current.advanceStatus,
        listener: (context, state) {
          if (state.cancelStatus == OrderCancelStatus.failure) {
            AppSnackBar.error(context, l10n.orderCancelErrorBody);
          }
          if (state.rateStatus == OrderRateStatus.failure) {
            AppSnackBar.error(context, l10n.orderRateErrorBody);
          }
          if (state.advanceStatus == OrderAdvanceStatus.failure) {
            AppSnackBar.error(context, l10n.orderActionErrorBody);
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
              role: role,
              customer: state.customer,
              area: state.area,
              isCancelling: state.isCancelling,
              isRating: state.isRating,
              isAdvancing: state.isAdvancing,
              onCancel: () => _confirmCancel(context),
              onRate: (rating) => context
                  .read<OrderDetailBloc>()
                  .add(OrderDetailRateSubmitted(rating)),
              onAdvance: (target) => _handleCourierAction(context, target),
            ),
        },
      ),
    );
  }
}

class _OrderDetailContent extends StatelessWidget {
  const _OrderDetailContent({
    required this.order,
    required this.role,
    required this.customer,
    required this.area,
    required this.isCancelling,
    required this.isRating,
    required this.isAdvancing,
    required this.onCancel,
    required this.onRate,
    required this.onAdvance,
  });

  final Order order;
  final OrderViewerRole role;

  /// The customer's `/users` profile — owner/courier view only, resolved by
  /// the bloc. Null while it's still loading or the doc is missing.
  final AppUser? customer;

  /// The delivery area's display name — courier view only (M10).
  final Area? area;
  final bool isCancelling;
  final bool isRating;
  final bool isAdvancing;
  final VoidCallback onCancel;
  final ValueChanged<int> onRate;
  final ValueChanged<OrderStatus> onAdvance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final view = orderStatusView(l10n, order.status);
    final isOwner = role == OrderViewerRole.owner;
    final isCourier = role == OrderViewerRole.courier;
    final areaName = area == null ? null : (locale == 'ar' ? area!.nameAr : area!.nameEn);
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
              _AddressCard(order: order, areaName: areaName),
              if (role == OrderViewerRole.customer &&
                  order.status == OrderStatus.delivered) ...[
                const SizedBox(height: AppSpacing.lg),
                _RatingCard(
                  rating: order.rating,
                  isRating: isRating,
                  onRate: onRate,
                ),
              ],
              if (role != OrderViewerRole.customer && customer != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.orderCustomerSection, style: text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                _CustomerContactCard(customer: customer!),
              ],
              if (isOwner) ...[
                const SizedBox(height: AppSpacing.lg),
                _OwnerPaymentCard(order: order),
              ],
              if (order.driverUid != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.orderDriverSection, style: text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                _DriverCard(order: order, locale: locale),
              ] else if (isOwner &&
                  (order.status == OrderStatus.accepted ||
                      order.status == OrderStatus.preparing)) ...[
                const SizedBox(height: AppSpacing.lg),
                _AssignDriverButton(order: order),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.orderTimelineTitle, style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              _OrderTimeline(order: order),
            ],
          ),
        ),
        if (role == OrderViewerRole.customer && order.status.isCancellable)
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
          )
        else if (isCourier && courierPrimaryAction(l10n, order.status) != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: scheme.outline)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: FilledButton(
                  onPressed: isAdvancing
                      ? null
                      : () => onAdvance(
                          courierPrimaryAction(l10n, order.status)!.target),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                  ),
                  child: isAdvancing
                      ? const SizedBox(
                          width: AppSpacing.lg,
                          height: AppSpacing.lg,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(courierPrimaryAction(l10n, order.status)!.label),
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

/// Shown only for a delivered order. Before rating: a prompt + tap-to-rate
/// stars (submits on tap, no confirm step). After: a read-only star row —
/// the same card slot, no layout jump between the two states.
class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.rating,
    required this.isRating,
    required this.onRate,
  });

  final int? rating;
  final bool isRating;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration:
          BoxDecoration(color: scheme.surface, borderRadius: AppRadius.lgAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rating == null ? l10n.orderRateTitle : l10n.orderRatedTitle,
            style: text.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (rating == null) ...[
            Text(
              l10n.orderRateBody,
              style: text.bodySmall
                  ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: AppSpacing.sm),
            StarRatingPicker(onRate: isRating ? null : onRate),
          ] else
            StarRatingDisplay(filled: rating!),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.order, this.areaName});

  final Order order;

  /// The delivery area's display name — courier view only (M10). Optional
  /// secondary info, never blocks the card if it's null.
  final String? areaName;

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
                if (areaName != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    areaName!,
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
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

/// Owner+courier: the customer's name + phone (M2, widened to courier M10).
/// Phone shows as selectable text rather than a `tel:` link — `url_launcher`
/// isn't a dependency here and this session doesn't add one.
class _CustomerContactCard extends StatelessWidget {
  const _CustomerContactCard({required this.customer});

  final AppUser customer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final phone = customer.phone;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration:
          BoxDecoration(color: scheme.surface, borderRadius: AppRadius.lgAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 20, color: scheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(customer.name, style: text.bodyMedium),
              ),
            ],
          ),
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.call_outlined,
                    size: 20, color: scheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: AppSpacing.sm),
                SelectableText(phone, style: text.bodyMedium),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Owner-only: payment method + subtotal/delivery-fee/total (M2; real fee
/// fields landed in M12). Orders placed before M12 have no stored
/// subtotal/fee — `Order.subtotalMinor` falls back to `totalMinor` and
/// `deliveryFeeMinor` defaults to 0, which reproduces the old placeholder
/// display for them.
class _OwnerPaymentCard extends StatelessWidget {
  const _OwnerPaymentCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget row(String label, Widget value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(child: Text(label, style: text.bodyMedium)),
              value,
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration:
          BoxDecoration(color: scheme.surface, borderRadius: AppRadius.lgAll),
      child: Column(
        children: [
          row(l10n.orderPaymentMethod, Text(l10n.codLabel, style: text.bodyMedium)),
          const Divider(height: AppSpacing.lg),
          row(l10n.orderSubtotalLabel, PriceTag(order.subtotalMinor)),
          row(l10n.orderDeliveryFeeLabel, PriceTag(order.deliveryFeeMinor)),
          row(
            l10n.cartTotal,
            PriceTag(
              order.totalMinor,
              style: text.titleSmall
                  ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Assigned courier's name/phone/assigned-time (M9, Task D) — shown to both
/// the owner and the customer once `order.driverUid` is set. Phone shows as
/// selectable text, same reasoning as `_OwnerCustomerCard`.
class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.order, required this.locale});

  final Order order;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final phone = order.driverPhone;
    final assignedAt = order.assignedAt;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration:
          BoxDecoration(color: scheme.surface, borderRadius: AppRadius.lgAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.delivery_dining_outlined,
                  size: 20, color: scheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(order.driverName ?? '', style: text.bodyMedium),
              ),
            ],
          ),
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.call_outlined,
                    size: 20, color: scheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: AppSpacing.sm),
                SelectableText(phone, style: text.bodyMedium),
              ],
            ),
          ],
          if (assignedAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.orderAssignedAtLabel} '
              '${DateFormat.yMMMd(locale).add_Hm().format(assignedAt)}',
              style: text.bodySmall
                  ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Owner-only "assign courier" trigger (M9, Task C) — shown while the order
/// is accepted/preparing and no driver is set yet; opens the assignment
/// sheet. Success needs no local patch: the new driver fields arrive through
/// the page's own watch stream, same pattern as cancel/rate.
class _AssignDriverButton extends StatelessWidget {
  const _AssignDriverButton({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return OutlinedButton.icon(
      onPressed: () => showAssignDriverSheet(context, order),
      icon: const Icon(Icons.delivery_dining_outlined),
      label: Text(l10n.orderAssignDriverButton),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }
}

/// Bottom-of-page status timeline (M2, Task B): oldest first, one row per
/// [StatusChange]. Old seeded orders have an empty `statusHistory` — that
/// falls back to a single row built from the order's current status +
/// createdAt, never a blank section (designed-states rule).
class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final history = order.statusHistory.isNotEmpty
        ? order.statusHistory
        : [
            StatusChange(
              status: order.status,
              at: order.createdAt,
              byUid: order.customerUid,
            ),
          ];
    final timeFormat = DateFormat.yMMMd(locale).add_Hm();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration:
          BoxDecoration(color: scheme.surface, borderRadius: AppRadius.lgAll),
      child: Column(
        children: [
          for (var i = 0; i < history.length; i++) ...[
            _TimelineRow(
              label: orderStatusView(l10n, history[i].status).label,
              tone: orderStatusView(l10n, history[i].status).tone,
              time: timeFormat.format(history[i].at),
              isLast: i == history.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.tone,
    required this.time,
    required this.isLast,
  });

  final String label;
  final StatusTone tone;
  final String time;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StatusChip(label: label, tone: tone),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              time,
              style: text.bodySmall
                  ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
