import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/areas/entities/area.dart';
import '../../../domain/areas/usecases/get_areas.dart';
import '../../../domain/driver/entities/driver.dart';
import '../../../domain/driver/usecases/available_drivers.dart';
import '../../../domain/order/entities/order.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeletons.dart';
import '../bloc/order_detail_bloc.dart';

/// Staff "reassign driver" sheet (FC10) — reuses the M9 assignment sheet's
/// list UI (`AvailableDrivers` over the order's area), but submits through
/// the Worker (`OrderDetailReassignRequested`, always with a reason) instead
/// of the client-side assignment transaction, and adds a current-driver
/// header + an "إلغاء التعيين" (unassign) option `assign_driver_sheet` has no
/// use for.
Future<void> showReassignDriverSheet(BuildContext context, Order order) {
  final bloc = context.read<OrderDetailBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _ReassignDriverSheet(order: order),
    ),
  );
}

class _ReassignDriverSheet extends StatefulWidget {
  const _ReassignDriverSheet({required this.order});

  final Order order;

  @override
  State<_ReassignDriverSheet> createState() => _ReassignDriverSheetState();
}

class _ReassignDriverSheetState extends State<_ReassignDriverSheet> {
  late final Future<({List<Driver> drivers, List<Area> areas})> _future = _load();

  Future<({List<Driver> drivers, List<Area> areas})> _load() async {
    final areaId = widget.order.deliveryAddress.areaId;
    final results = await Future.wait([
      areaId == null ? Future.value(<Driver>[]) : sl<AvailableDrivers>()(areaId),
      sl<GetAreas>()(),
    ]);
    return (drivers: results[0] as List<Driver>, areas: results[1] as List<Area>);
  }

  Future<void> _confirm({String? newDriverUid, bool clear = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(clear ? l10n.orderUnassignDriverAction : l10n.orderReassignDriverAction),
          content: TextField(
            controller: reasonCtrl,
            maxLines: 2,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.orderStaffReasonLabel),
            onChanged: (_) => setState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: reasonCtrl.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(dialogContext).pop(reasonCtrl.text.trim()),
              child: Text(clear ? l10n.orderUnassignDriverAction : l10n.orderReassignDriverAction),
            ),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;

    context.read<OrderDetailBloc>().add(OrderDetailReassignRequested(
          newDriverUid: newDriverUid,
          clear: clear,
          reason: reason,
        ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final currentDriverUid = widget.order.driverUid;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.orderReassignDriverAction, style: text.titleMedium),
            if (currentDriverUid != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${l10n.orderDriverSection}: ${widget.order.driverName ?? currentDriverUid}',
                style: text.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => _confirm(clear: true),
                child: Text(l10n.orderUnassignDriverAction),
              ),
              const Divider(height: AppSpacing.lg),
            ],
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
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
                      .where((d) =>
                          d.activeOrdersCount < d.maxActiveOrders && d.uid != currentDriverUid)
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
                      onTap: () => _confirm(newDriverUid: eligible[i].uid),
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
    required this.onTap,
  });

  final Driver driver;
  final Map<String, Area> areaNames;
  final bool isArabic;
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
      onTap: onTap,
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
