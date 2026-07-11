import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/areas/entities/area.dart';
import '../../../domain/driver/entities/driver.dart';
import '../../../domain/driver/usecases/set_driver_online.dart';
import '../../../domain/driver/usecases/watch_driver.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/shop/entities/shop.dart';
import '../../../domain/shop/usecases/watch_shop.dart';
import '../../../l10n/app_localizations.dart';
import '../../orders/order_status_view.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/price_tag.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/common/status_chip.dart';
import '../bloc/deliveries_bloc.dart';

/// The courier's deliveries tab (Session 10) — role-routed from the Session 8
/// placeholder. An online/offline switch and suspended banner sit above a
/// segmented Active/History list; tapping a card opens the shared
/// `OrderDetailPage` in its courier role.
class DeliveriesPage extends StatelessWidget {
  const DeliveriesPage({super.key, required this.driverUid});

  final String driverUid;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<DeliveriesBloc>(param1: driverUid)..add(const DeliveriesStarted()),
      child: _DeliveriesView(driverUid: driverUid),
    );
  }
}

class _DeliveriesView extends StatefulWidget {
  const _DeliveriesView({required this.driverUid});

  final String driverUid;

  @override
  State<_DeliveriesView> createState() => _DeliveriesViewState();
}

class _DeliveriesViewState extends State<_DeliveriesView> {
  late final Stream<Driver?> _driverStream = sl<WatchDriver>()(widget.driverUid);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<Driver?>(
      stream: _driverStream,
      builder: (context, snapshot) {
        final driver = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.navDeliveries),
            actions: [
              if (driver != null && !driver.isSuspended)
                _OnlineSwitch(driverUid: widget.driverUid, driver: driver),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (driver?.isSuspended == true) const _SuspendedBanner(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: _TabSwitcher(),
                ),
                const Expanded(child: _DeliveriesList()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnlineSwitch extends StatelessWidget {
  const _OnlineSwitch({required this.driverUid, required this.driver});

  final String driverUid;
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            driver.isOnline ? l10n.courierOnlineLabel : l10n.courierOfflineLabel,
            style: text.bodySmall,
          ),
          Switch(
            value: driver.isOnline,
            onChanged: (value) => sl<SetDriverOnline>()(driverUid, value),
          ),
        ],
      ),
    );
  }
}

class _SuspendedBanner extends StatelessWidget {
  const _SuspendedBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.courierSuspendedBannerBody,
              style: text.bodySmall?.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tab = context.select((DeliveriesBloc bloc) => bloc.state.tab);

    return SegmentedButton<DeliveriesTab>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: DeliveriesTab.active,
          label: Text(l10n.courierActiveTabLabel),
        ),
        ButtonSegment(
          value: DeliveriesTab.history,
          label: Text(l10n.courierHistoryTabLabel),
        ),
      ],
      selected: {tab},
      onSelectionChanged: (selection) => context
          .read<DeliveriesBloc>()
          .add(DeliveriesTabChanged(selection.first)),
    );
  }
}

class _DeliveriesList extends StatelessWidget {
  const _DeliveriesList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<DeliveriesBloc, DeliveriesState>(
      builder: (context, state) {
        final isActive = state.tab == DeliveriesTab.active;
        final status = isActive ? state.activeStatus : state.historyStatus;
        final orders = isActive ? state.activeOrders : state.historyOrders;

        return switch (status) {
          DeliveriesListStatus.loading => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: ListShimmer(),
            ),
          DeliveriesListStatus.error => EmptyState(
              icon: Icons.wifi_off_rounded,
              title: l10n.errorTitle,
              message: l10n.ordersErrorBody,
            ),
          DeliveriesListStatus.loaded => orders.isEmpty
              ? EmptyState(
                  icon: isActive
                      ? Icons.local_shipping_outlined
                      : Icons.history_rounded,
                  title: isActive
                      ? l10n.courierActiveEmptyTitle
                      : l10n.courierHistoryEmptyTitle,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) =>
                      _DeliveryCard(order: orders[i], areas: state.areas),
                ),
        };
      },
    );
  }
}

class _DeliveryCard extends StatefulWidget {
  const _DeliveryCard({required this.order, required this.areas});

  final Order order;
  final List<Area> areas;

  @override
  State<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<_DeliveryCard> {
  late final Future<Shop> _shopFuture =
      sl<WatchShop>()(widget.order.shopId).first;

  Area? _areaFor(String? areaId) {
    if (areaId == null) return null;
    for (final area in widget.areas) {
      if (area.id == areaId) return area;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final order = widget.order;
    final view = orderStatusView(l10n, order.status);
    final area = _areaFor(order.deliveryAddress.areaId);
    final dim = text.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6));

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push('/order/${order.id}?role=courier'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FutureBuilder<Shop>(
                  future: _shopFuture,
                  builder: (context, snapshot) {
                    final shop = snapshot.data;
                    final name =
                        shop == null ? '…' : (isArabic ? shop.nameAr : shop.name);
                    return Text(
                      name,
                      style: text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              StatusChip(label: view.label, tone: view.tone),
            ],
          ),
          if (area != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(isArabic ? area.nameAr : area.nameEn, style: dim),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.shopping_basket_outlined, size: 16, color: dim?.color),
              const SizedBox(width: AppSpacing.xs),
              Text('${order.items.length}', style: text.bodySmall),
              const Spacer(),
              PriceTag(order.totalMinor),
            ],
          ),
        ],
      ),
    );
  }
}
