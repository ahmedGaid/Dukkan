import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/driver/entities/driver.dart';
import '../../../../domain/order/entities/order.dart';
import '../../../../domain/storage/entities/storage_folder.dart';
import '../../../../domain/storage/usecases/upload_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orders/order_status_view.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/shimmer_image.dart';
import '../../../widgets/common/skeletons.dart';
import '../../../widgets/common/status_chip.dart';
import '../bloc/driver_detail_bloc.dart';

/// The Founder Console driver detail page (`/console/drivers/:uid`, FC11).
/// Always opened from the board row's `extra: Driver` (mirrors
/// `ShopDetailPage` — no get-by-id-without-seed on this route).
class DriverDetailPage extends StatelessWidget {
  const DriverDetailPage({super.key, required this.seed});

  final Driver? seed;

  @override
  Widget build(BuildContext context) {
    final seed = this.seed;
    if (seed == null) {
      final l10n = AppLocalizations.of(context)!;
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.driverDetailMissingSeed, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () => context.go('/console/drivers'),
                  child: Text(l10n.userDetailBackToList),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => sl<DriverDetailBloc>(param1: seed),
      child: const _DriverDetailView(),
    );
  }
}

class _DriverDetailView extends StatelessWidget {
  const _DriverDetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<DriverDetailBloc, DriverDetailState>(
      listenWhen: (a, b) => a.actionBusy && !b.actionBusy,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.actionError != null) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.userDetailActionFailed)));
        } else {
          messenger.showSnackBar(SnackBar(content: Text(l10n.userDetailActionOk)));
        }
      },
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _Header(),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: BlocBuilder<DriverDetailBloc, DriverDetailState>(
                builder: (context, state) => SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusCard(state: state),
                      const SizedBox(height: AppSpacing.md),
                      _EditableFieldsCard(state: state),
                      const SizedBox(height: AppSpacing.md),
                      _PerformanceCard(state: state),
                      const SizedBox(height: AppSpacing.md),
                      _AssignedOrdersCard(state: state),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final driver = context.select((DriverDetailBloc b) => b.state.driver);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/console/drivers'),
          ),
          Expanded(
            child: Text(
              driver.name,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (context.select((DriverDetailBloc b) => b.state.actionBusy))
            const Padding(
              padding: EdgeInsetsDirectional.only(end: AppSpacing.md),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Status
// ─────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final DriverDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final driver = state.driver;
    final busy = state.actionBusy;
    final bloc = context.read<DriverDetailBloc>();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.driverDetailStatusTitle, style: Theme.of(context).textTheme.titleSmall),
              ),
              StatusChip(
                label: driver.isSuspended ? l10n.driversFilterSuspended : l10n.driversFilterActive,
                tone: driver.isSuspended ? StatusTone.caution : StatusTone.positive,
              ),
            ],
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: !driver.isSuspended,
            onChanged: busy
                ? null
                : (activate) async {
                    if (activate) {
                      bloc.add(const DriverDetailSetSuspendedRequested(value: false));
                    } else {
                      final reason = await _suspendReasonDialog(context);
                      if (reason != null) {
                        bloc.add(DriverDetailSetSuspendedRequested(value: true, reason: reason));
                      }
                    }
                  },
            title: Text(l10n.driverDetailActiveSwitch),
            subtitle: driver.isSuspended && driver.suspendReason != null
                ? Text(driver.suspendReason!)
                : null,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: driver.isVerified,
            onChanged: busy ? null : (v) => bloc.add(DriverDetailSetVerifiedRequested(v)),
            title: Text(l10n.driverDetailVerifiedSwitch),
          ),
        ],
      ),
    );
  }

  Future<String?> _suspendReasonDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.driverDetailSuspendTitle),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            decoration: InputDecoration(labelText: l10n.driverDetailSuspendReasonLabel),
            validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(ctrl.text.trim());
              }
            },
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Editable fields
// ─────────────────────────────────────────────────────────────────────────

class _EditableFieldsCard extends StatefulWidget {
  const _EditableFieldsCard({required this.state});

  final DriverDetailState state;

  @override
  State<_EditableFieldsCard> createState() => _EditableFieldsCardState();
}

class _EditableFieldsCardState extends State<_EditableFieldsCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _vehicleType;
  late final TextEditingController _vehiclePlate;
  late int _maxActiveOrders;
  late Set<String> _areaIds;
  Uint8List? _newIdDocBytes;
  String? _newIdDocPath;
  bool _uploadingIdDoc = false;
  String? _driverUidForControllers;

  @override
  void initState() {
    super.initState();
    _resetControllers(widget.state.driver);
  }

  @override
  void didUpdateWidget(covariant _EditableFieldsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reset on a genuinely different driver (never happens here) or the
    // very first build — never clobber in-progress typing when this same
    // driver's state updates for an unrelated reason (e.g. a status flip
    // while staff edits the vehicle fields).
    if (_driverUidForControllers != widget.state.driver.uid) {
      _resetControllers(widget.state.driver);
    }
  }

  void _resetControllers(Driver driver) {
    _driverUidForControllers = driver.uid;
    _name = TextEditingController(text: driver.name);
    _phone = TextEditingController(text: driver.phone ?? '');
    _vehicleType = TextEditingController(text: driver.vehicleType ?? '');
    _vehiclePlate = TextEditingController(text: driver.vehiclePlate ?? '');
    _maxActiveOrders = driver.maxActiveOrders;
    _areaIds = driver.areaIds.toSet();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _vehicleType.dispose();
    _vehiclePlate.dispose();
    super.dispose();
  }

  Future<void> _pickIdDoc() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _newIdDocBytes = bytes;
      _newIdDocPath = file.path;
    });
  }

  String _mimeTypeFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context)!;
    String? idDocUrl = widget.state.driver.idDocUrl;
    final bytes = _newIdDocBytes;
    if (bytes != null) {
      setState(() => _uploadingIdDoc = true);
      try {
        idDocUrl = await sl<UploadImage>()(
          bytes: bytes,
          contentType: _mimeTypeFor(_newIdDocPath!),
          folder: StorageFolder.driverDocs,
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _uploadingIdDoc = false);
        AppSnackBar.error(context, l10n.driverDetailIdDocUploadError);
        return;
      }
      if (!mounted) return;
      setState(() => _uploadingIdDoc = false);
    }
    context.read<DriverDetailBloc>().add(DriverDetailUpdateRequested(
          name: _name.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          areaIds: _areaIds.toList(),
          maxActiveOrders: _maxActiveOrders,
          vehicleType: _vehicleType.text.trim().isEmpty ? null : _vehicleType.text.trim(),
          vehiclePlate: _vehiclePlate.text.trim().isEmpty ? null : _vehiclePlate.text.trim(),
          idDocUrl: idDocUrl,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final busy = widget.state.actionBusy || _uploadingIdDoc;
    final areas = widget.state.areas;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.driverDetailFieldsTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: l10n.fieldDriverName,
              controller: _name,
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
            ),
            AppTextField(label: l10n.fieldDriverPhone, controller: _phone),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.driverDetailAreasLabel, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final area in areas)
                  FilterChip(
                    label: Text(isArabic ? area.nameAr : area.nameEn),
                    selected: _areaIds.contains(area.id),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _areaIds.add(area.id);
                      } else {
                        _areaIds.remove(area.id);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _CapacityStepper(
              value: _maxActiveOrders,
              onChanged: (v) => setState(() => _maxActiveOrders = v),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: l10n.driverDetailVehicleTypeLabel, controller: _vehicleType),
            AppTextField(label: l10n.driverDetailVehiclePlateLabel, controller: _vehiclePlate),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.driverDetailIdDocLabel, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: _pickIdDoc,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _newIdDocBytes != null
                    ? Image.memory(_newIdDocBytes!, width: 96, height: 64, fit: BoxFit.cover)
                    : ShimmerImage(
                        url: widget.state.driver.idDocUrl,
                        width: 96,
                        height: 64,
                        fallbackIcon: Icons.badge_outlined,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: busy ? null : _save,
              child: busy
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4))
                  : Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapacityStepper extends StatelessWidget {
  const _CapacityStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Text(l10n.driverDetailMaxActiveOrdersLabel,
              style: Theme.of(context).textTheme.labelMedium),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 24,
          child: Text('$value', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < 10 ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Performance + assigned orders
// ─────────────────────────────────────────────────────────────────────────

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.state});

  final DriverDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final performance = state.performance;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.driverDetailPerformanceTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          if (!state.secondaryLoaded)
            const ListShimmer(count: 1, itemHeight: 48)
          else
            Row(
              children: [
                Expanded(
                  child: _PerformanceStat(
                    label: l10n.driverDetailActiveLoad,
                    value: '${state.driver.activeOrdersCount}/${state.driver.maxActiveOrders}',
                  ),
                ),
                Expanded(
                  child: _PerformanceStat(
                    label: l10n.driverDetailDeliveredThisMonth,
                    value: '${performance?.deliveredThisMonth ?? 0}',
                  ),
                ),
                Expanded(
                  child: _PerformanceStat(
                    label: l10n.driverDetailDeliveredTotal,
                    value: '${performance?.deliveredTotal ?? 0}',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PerformanceStat extends StatelessWidget {
  const _PerformanceStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: text.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }
}

class _AssignedOrdersCard extends StatelessWidget {
  const _AssignedOrdersCard({required this.state});

  final DriverDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.driverDetailAssignedOrdersTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          if (!state.secondaryLoaded)
            const ListShimmer(count: 2, itemHeight: 56)
          else if (state.assignedOrders.isEmpty)
            Text(
              l10n.driverDetailNoAssignedOrders,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            )
          else
            Column(
              children: [
                for (final order in state.assignedOrders) _AssignedOrderRow(order: order),
              ],
            ),
        ],
      ),
    );
  }
}

class _AssignedOrderRow extends StatelessWidget {
  const _AssignedOrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final view = orderStatusView(l10n, order.status);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('#${order.id.length > 8 ? order.id.substring(0, 8) : order.id}'),
      subtitle: Text(DateFormat.Md(locale).add_Hm().format(order.createdAt)),
      trailing: StatusChip(label: view.label, tone: view.tone),
      onTap: () => context.push('/order/${order.id}?role=staff'),
    );
  }
}
