import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../core/errors/failures.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/areas/entities/area.dart';
import '../../../domain/areas/usecases/get_areas.dart';
import '../../../domain/driver/entities/driver.dart';
import '../../../domain/driver/usecases/assign_driver.dart';
import '../../../domain/driver/usecases/available_drivers.dart';
import '../../../domain/notifications/repositories/notification_repository.dart';
import '../../../domain/notifications/usecases/notify_order_event.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/shop/usecases/watch_shop.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeletons.dart';

/// Owner's "assign driver" bottom sheet (M9, Task C). Lists active,
/// unsuspended drivers covering the order's area (server-filtered by
/// [AvailableDrivers]), then hides full ones client-side — the composite
/// index can't compare `activeOrdersCount` against `maxActiveOrders`. Tapping
/// a row confirms, then runs the assignment transaction; success just closes
/// the sheet — the order's own realtime stream fills the driver block on the
/// details page, no local patch needed.
Future<void> showAssignDriverSheet(BuildContext context, Order order) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AssignDriverSheet(order: order),
  );
}

class _AssignDriverSheet extends StatefulWidget {
  const _AssignDriverSheet({required this.order});

  final Order order;

  @override
  State<_AssignDriverSheet> createState() => _AssignDriverSheetState();
}

class _AssignDriverSheetState extends State<_AssignDriverSheet> {
  late final Future<({List<Driver> drivers, List<Area> areas})> _future = _load();
  bool _assigning = false;

  Future<({List<Driver> drivers, List<Area> areas})> _load() async {
    final areaId = widget.order.deliveryAddress.areaId;
    final results = await Future.wait([
      areaId == null ? Future.value(<Driver>[]) : sl<AvailableDrivers>()(areaId),
      sl<GetAreas>()(),
    ]);
    return (drivers: results[0] as List<Driver>, areas: results[1] as List<Area>);
  }

  Future<void> _confirmAndAssign(Driver driver) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.orderAssignDriverConfirmTitle),
        content: Text(l10n.orderAssignDriverConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.orderAssignDriverButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _assigning = true);
    try {
      await sl<AssignDriver>()(orderId: widget.order.id, driverUid: driver.uid);
      unawaited(_notifyDriver());
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, _errorMessage(l10n, error));
      setState(() => _assigning = false);
    }
  }

  /// Fire-and-forget push to the newly assigned courier (M11, Task A). Push
  /// text is decided at send time and bilingual, same reasoning as
  /// `_notifyCustomer`/`_notifyShopOwner` (order_desk_page/checkout_page).
  Future<void> _notifyDriver() async {
    final lAr = lookupAppLocalizations(const Locale('ar'));
    final lEn = lookupAppLocalizations(const Locale('en'));
    final areaId = widget.order.deliveryAddress.areaId;
    final areas = (await _future).areas.cast<Area?>();
    final area = areas.firstWhere((a) => a?.id == areaId, orElse: () => null);
    final shop = await sl<WatchShop>()(widget.order.shopId).first;
    await sl<NotifyOrderEvent>()(
      orderId: widget.order.id,
      type: NotificationEventType.driverAssigned,
      title: '${lAr.notifyDriverAssignedTitle} / ${lEn.notifyDriverAssignedTitle}',
      body: '${lAr.notifyDriverAssignedBody(area?.nameAr ?? '', shop.nameAr)} / '
          '${lEn.notifyDriverAssignedBody(area?.nameEn ?? '', shop.name)}',
    );
  }

  String _errorMessage(AppLocalizations l10n, Object error) {
    if (error is DriverUnavailable) {
      return switch (error.reason) {
        DriverUnavailableReason.offline => l10n.orderAssignDriverErrorOffline,
        DriverUnavailableReason.capacity => l10n.orderAssignDriverErrorCapacity,
        DriverUnavailableReason.area => l10n.orderAssignDriverErrorArea,
        DriverUnavailableReason.taken => l10n.orderAssignDriverErrorTaken,
        DriverUnavailableReason.suspended ||
        DriverUnavailableReason.status =>
          l10n.orderAssignDriverErrorGeneric,
      };
    }
    return l10n.orderAssignDriverErrorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.orderAssignDriverSheetTitle, style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: FutureBuilder<({List<Driver> drivers, List<Area> areas})>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.lg),
                      child: ListShimmer(count: 3, itemHeight: 64),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: EmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: l10n.errorTitle,
                        message: l10n.orderAssignDriverErrorGeneric,
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  final areaNames = {for (final a in data.areas) a.id: a};
                  final eligible = data.drivers
                      .where((d) => d.activeOrdersCount < d.maxActiveOrders)
                      .toList();

                  if (eligible.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: EmptyState(
                        icon: Icons.moped_outlined,
                        title: l10n.orderAssignDriverEmptyTitle,
                        message: l10n.orderAssignDriverEmptyBody,
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: eligible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) => _DriverRow(
                      driver: eligible[i],
                      areaNames: areaNames,
                      isArabic: isArabic,
                      enabled: !_assigning,
                      onTap: () => _confirmAndAssign(eligible[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({
    required this.driver,
    required this.areaNames,
    required this.isArabic,
    required this.enabled,
    required this.onTap,
  });

  final Driver driver;
  final Map<String, Area> areaNames;
  final bool isArabic;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final areasLabel = driver.areaIds
        .map((id) => areaNames[id])
        .whereType<Area>()
        .map((a) => isArabic ? a.nameAr : a.nameEn)
        .join(isArabic ? '، ' : ', ');
    final digits = NumberFormat.decimalPattern(isArabic ? 'ar' : 'en');
    final capacity =
        '${digits.format(driver.activeOrdersCount)} / ${digits.format(driver.maxActiveOrders)}';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: enabled ? onTap : null,
      child: Row(
        children: [
          Icon(Icons.moped_outlined, color: scheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(driver.name, style: text.bodyMedium),
                if (areasLabel.isNotEmpty)
                  Text(
                    areasLabel,
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
                  ),
              ],
            ),
          ),
          Text(capacity, style: text.bodyMedium),
        ],
      ),
    );
  }
}
