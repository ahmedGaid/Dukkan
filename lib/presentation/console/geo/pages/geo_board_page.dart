import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/admin/usecases/count_orders_in_area.dart';
import '../../../../domain/areas/entities/area.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/skeletons.dart';
import '../bloc/geo_board_bloc.dart';

/// The Founder Console geo board (`/console/geo`, FC9). Grouped
/// governorate → city → areas; the list is small so it loads at once — no
/// search/pagination, mirroring `TaxonomyBoardPage`. Delete is only offered
/// when no order references the area ([CountOrdersInArea] == 0); otherwise
/// the confirm dialog forces "deactivate instead" (Task C).
class GeoBoardPage extends StatelessWidget {
  const GeoBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GeoBoardBloc>()..add(const GeoBoardStarted()),
      child: const _GeoBoardView(),
    );
  }
}

class _GeoBoardView extends StatelessWidget {
  const _GeoBoardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: BlocConsumer<GeoBoardBloc, GeoBoardState>(
        listenWhen: (a, b) => a.actionError != b.actionError,
        listener: (context, state) {
          if (state.actionError) {
            AppSnackBar.error(context, l10n.geoBoardActionFailed);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(l10n.geoBoardHint, style: Theme.of(context).textTheme.bodySmall),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: () => _openAreaSheet(context, existing: state.areas),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.geoBoardAddAction),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: switch (state.status) {
                  GeoBoardStatus.loading => const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: ListShimmer(),
                    ),
                  GeoBoardStatus.error => EmptyState(
                      icon: Icons.error_outline,
                      title: l10n.errorTitle,
                      message: l10n.geoBoardErrorBody,
                      actionLabel: l10n.actionRetry,
                      onAction: () =>
                          context.read<GeoBoardBloc>().add(const GeoBoardRetryRequested()),
                    ),
                  GeoBoardStatus.loaded => state.areas.isEmpty
                      ? EmptyState(
                          icon: Icons.map_outlined,
                          title: l10n.geoBoardEmptyTitle,
                          actionLabel: l10n.geoBoardAddAction,
                          onAction: () => _openAreaSheet(context, existing: state.areas),
                        )
                      : _GroupedAreaList(areas: state.areas),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One entry per (governorate, city) pair, in first-seen order — [areas] is
/// already sorted by `sort`, so this just folds it into display groups.
class _CityGroup {
  _CityGroup(this.governorate, this.city) : areas = [];
  final String governorate;
  final String city;
  final List<Area> areas;
}

List<_CityGroup> _groupByCity(List<Area> areas) {
  final groups = <String, _CityGroup>{};
  for (final area in areas) {
    final key = '${area.governorate}|${area.city}';
    groups.putIfAbsent(key, () => _CityGroup(area.governorate, area.city)).areas.add(area);
  }
  return groups.values.toList(growable: false);
}

class _GroupedAreaList extends StatelessWidget {
  const _GroupedAreaList({required this.areas});

  final List<Area> areas;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByCity(areas);

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final group = groups[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${group.governorate} · ${group.city}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final area in group.areas) ...[
                _AreaRow(area: area, existing: areas),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AreaRow extends StatelessWidget {
  const _AreaRow({required this.area, required this.existing});

  final Area area;
  final List<Area> existing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final bloc = context.read<GeoBoardBloc>();
    final muted = scheme.onSurface.withValues(alpha: 0.6);

    return Material(
      color: scheme.surface,
      borderRadius: AppRadius.mdAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isArabic ? area.nameAr : area.nameEn,
                    style: text.titleSmall?.copyWith(
                      color: area.isActive ? null : muted,
                      decoration: area.isActive ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  if (area.deliveryFeeMinorOverride != null)
                    Text(
                      l10n.geoBoardFeeOverrideBadge(
                        Money.format(area.deliveryFeeMinorOverride!, languageCode: isArabic ? 'ar' : 'en'),
                      ),
                      style: text.bodySmall?.copyWith(color: muted),
                    ),
                ],
              ),
            ),
            Switch(
              value: area.isActive,
              onChanged: (v) => bloc.add(GeoBoardActiveToggled(area.id, v)),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openAreaSheet(context, existing: existing, area: area),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDeleteOrDeactivate(context, area),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteOrDeactivate(BuildContext context, Area area) async {
  final l10n = AppLocalizations.of(context)!;
  final bloc = context.read<GeoBoardBloc>();
  final count = await sl<CountOrdersInArea>()(area.id);
  if (!context.mounted) return;

  if (count > 0) {
    final deactivate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.geoBoardDeactivateInsteadTitle),
        content: Text(l10n.geoBoardDeactivateInsteadBody(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.geoBoardDeactivateAction),
          ),
        ],
      ),
    );
    if (deactivate == true) {
      bloc.add(GeoBoardActiveToggled(area.id, false));
    }
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.geoBoardDeleteConfirmTitle),
      content: Text(l10n.geoBoardDeleteConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.actionDelete),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    bloc.add(GeoBoardDeleteRequested(area.id));
  }
}

Future<void> _openAreaSheet(
  BuildContext context, {
  required List<Area> existing,
  Area? area,
}) {
  final bloc = context.read<GeoBoardBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => BlocProvider.value(
      value: bloc,
      child: _AreaSheet(area: area, existing: existing),
    ),
  );
}

/// Distinct, order-preserved values — the governorate/city suggestion chips'
/// source list.
List<String> _uniqueValues(Iterable<String> values) {
  final seen = <String>{};
  final out = <String>[];
  for (final v in values) {
    if (seen.add(v)) out.add(v);
  }
  return out;
}

/// A tap-to-fill row of already-used governorate/city values — lighter than
/// a full `Autocomplete` widget, and keeps `AppTextField`'s themed input
/// styling intact (Task C's "autocomplete from existing values").
class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({required this.values, required this.onSelect});

  final List<String> values;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final v in values)
          ActionChip(label: Text(v), onPressed: () => onSelect(v)),
      ],
    );
  }
}

/// Create/edit form — same sheet, pre-filled in edit mode. Governorate/city
/// autocomplete from [existing]'s already-used values (Egypt-only, no
/// country/postal field — see `FILE_09_TAXONOMY_GEO.md`).
class _AreaSheet extends StatefulWidget {
  const _AreaSheet({this.area, required this.existing});

  final Area? area;
  final List<Area> existing;

  bool get isEdit => area != null;

  @override
  State<_AreaSheet> createState() => _AreaSheetState();
}

class _AreaSheetState extends State<_AreaSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameAr = TextEditingController(text: widget.area?.nameAr ?? '');
  late final _nameEn = TextEditingController(text: widget.area?.nameEn ?? '');
  late final _governorate =
      TextEditingController(text: widget.area?.governorate ?? 'الإسماعيلية');
  late final _city = TextEditingController(text: widget.area?.city ?? 'الإسماعيلية');
  late final _feeOverride = TextEditingController(
    text: widget.area?.deliveryFeeMinorOverride == null
        ? ''
        : (widget.area!.deliveryFeeMinorOverride! / 100).toStringAsFixed(2),
  );

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    _governorate.dispose();
    _city.dispose();
    _feeOverride.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bloc = context.read<GeoBoardBloc>();
    final feeText = _feeOverride.text.trim();
    final feeOverride = feeText.isEmpty ? null : Money.parseToMinor(feeText);
    if (widget.isEdit) {
      bloc.add(GeoBoardUpdateRequested(
        areaId: widget.area!.id,
        nameAr: _nameAr.text.trim(),
        nameEn: _nameEn.text.trim(),
        governorate: _governorate.text.trim(),
        city: _city.text.trim(),
        deliveryFeeMinorOverride: feeOverride,
      ));
    } else {
      bloc.add(GeoBoardCreateRequested(
        nameAr: _nameAr.text.trim(),
        nameEn: _nameEn.text.trim(),
        governorate: _governorate.text.trim(),
        city: _city.text.trim(),
        deliveryFeeMinorOverride: feeOverride,
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isEdit ? l10n.geoBoardEditTitle : l10n.geoBoardAddAction,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.fieldAreaNameAr,
                controller: _nameAr,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
              ),
              AppTextField(
                label: l10n.fieldAreaNameEn,
                controller: _nameEn,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
              ),
              AppTextField(
                label: l10n.fieldGovernorate,
                controller: _governorate,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
              ),
              _SuggestionChips(
                values: _uniqueValues(widget.existing.map((a) => a.governorate)),
                onSelect: (v) => setState(() => _governorate.text = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: l10n.fieldCity,
                controller: _city,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
              ),
              _SuggestionChips(
                values: _uniqueValues(widget.existing.map((a) => a.city)),
                onSelect: (v) => setState(() => _city.text = v),
              ),
              AppTextField(
                label: l10n.fieldDeliveryFeeOverrideOptional,
                controller: _feeOverride,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return Money.parseToMinor(v) == null ? l10n.validateAmountInvalid : null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: widget.isEdit ? l10n.actionSave : l10n.actionCreate,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
