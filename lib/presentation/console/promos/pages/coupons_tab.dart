import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/money.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/promos/entities/coupon.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/skeletons.dart';
import '../bloc/coupons_board_bloc.dart';

class CouponsTab extends StatelessWidget {
  const CouponsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<CouponsBoardBloc, CouponsBoardState>(
      listenWhen: (a, b) => a.actionError != b.actionError,
      listener: (context, state) {
        if (state.actionError) {
          AppSnackBar.error(context, l10n.promosActionFailed);
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
                    child: Text(
                      l10n.promosCouponsHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: () => _openCouponSheet(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.promosCouponsAddAction),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: switch (state.status) {
                CouponsBoardStatus.loading =>
                  const Padding(padding: EdgeInsets.all(AppSpacing.md), child: ListShimmer()),
                CouponsBoardStatus.error => EmptyState(
                    icon: Icons.error_outline,
                    title: l10n.errorTitle,
                    message: l10n.promosCouponsErrorBody,
                    actionLabel: l10n.actionRetry,
                    onAction: () => context
                        .read<CouponsBoardBloc>()
                        .add(const CouponsBoardRetryRequested()),
                  ),
                CouponsBoardStatus.loaded => state.coupons.isEmpty
                    ? EmptyState(
                        icon: Icons.local_offer_outlined,
                        title: l10n.promosCouponsEmptyTitle,
                        actionLabel: l10n.promosCouponsAddAction,
                        onAction: () => _openCouponSheet(context),
                      )
                    : _CouponList(coupons: state.coupons),
              },
            ),
          ],
        );
      },
    );
  }
}

class _CouponList extends StatelessWidget {
  const _CouponList({required this.coupons});

  final List<Coupon> coupons;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: coupons.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => _CouponRow(coupon: coupons[i]),
    );
  }
}

class _CouponRow extends StatelessWidget {
  const _CouponRow({required this.coupon});

  final Coupon coupon;

  String _valueLabel(AppLocalizations l10n, String languageCode) {
    if (coupon.type == CouponType.percent) {
      final percent = (coupon.valueBps ?? 0) / 100;
      final clean = percent % 1 == 0 ? percent.toInt().toString() : percent.toString();
      return l10n.promosCouponPercentValue(clean);
    }
    return Money.format(coupon.valueMinor ?? 0, languageCode: languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final bloc = context.read<CouponsBoardBloc>();
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final maxUses = coupon.maxUses;

    return Material(
      color: scheme.surface,
      borderRadius: AppRadius.mdAll,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        coupon.code,
                        style: text.titleSmall?.copyWith(
                          decoration: coupon.isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(_valueLabel(l10n, languageCode), style: text.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    maxUses == null
                        ? l10n.promosCouponUsageUnlimited(coupon.usedCount)
                        : l10n.promosCouponUsage(coupon.usedCount, maxUses),
                    style: text.bodySmall?.copyWith(color: muted),
                  ),
                  if (coupon.expiresAt != null)
                    Text(
                      l10n.promosCouponExpires(
                        DateFormat.yMMMd(languageCode).format(coupon.expiresAt!),
                      ),
                      style: text.bodySmall?.copyWith(color: muted),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(coupon.isActive ? Icons.toggle_on : Icons.toggle_off_outlined),
              color: coupon.isActive ? scheme.primary : muted,
              tooltip: coupon.isActive ? l10n.actionDeactivate : l10n.actionActivate,
              onPressed: () => bloc.add(
                CouponsBoardActiveToggled(coupon.code, !coupon.isActive),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openCouponSheet(context, coupon: coupon),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDeleteCoupon(context, coupon),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteCoupon(BuildContext context, Coupon coupon) async {
  final l10n = AppLocalizations.of(context)!;
  final bloc = context.read<CouponsBoardBloc>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.promosCouponDeleteConfirmTitle),
      content: Text(l10n.promosCouponDeleteConfirmBody(coupon.code)),
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
    bloc.add(CouponsBoardDeleteRequested(coupon.code));
  }
}

Future<void> _openCouponSheet(BuildContext context, {Coupon? coupon}) {
  final bloc = context.read<CouponsBoardBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => BlocProvider.value(
      value: bloc,
      child: _CouponSheet(coupon: coupon),
    ),
  );
}

/// Create/edit form. Code is the doc id — locked once created (matches the
/// rules-side immutability). Value field switches meaning (%/EGP) with the
/// type toggle, same UX as the products board's bulk-price dialog.
class _CouponSheet extends StatefulWidget {
  const _CouponSheet({this.coupon});

  final Coupon? coupon;

  @override
  State<_CouponSheet> createState() => _CouponSheetState();
}

class _CouponSheetState extends State<_CouponSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.coupon?.code ?? '');
  late final _value = TextEditingController(
    text: widget.coupon == null
        ? ''
        : widget.coupon!.type == CouponType.percent
            ? ((widget.coupon!.valueBps ?? 0) / 100).toString()
            : ((widget.coupon!.valueMinor ?? 0) / 100).toString(),
  );
  late final _minOrder = TextEditingController(
    text: widget.coupon == null ? '0' : ((widget.coupon!.minOrderMinor) / 100).toString(),
  );
  late final _maxUses =
      TextEditingController(text: widget.coupon?.maxUses?.toString() ?? '');
  late CouponType _type = widget.coupon?.type ?? CouponType.percent;
  late DateTime? _expiresAt = widget.coupon?.expiresAt;

  bool get _isEdit => widget.coupon != null;

  @override
  void dispose() {
    _code.dispose();
    _value.dispose();
    _minOrder.dispose();
    _maxUses.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bloc = context.read<CouponsBoardBloc>();
    final valueNumber = double.tryParse(_value.text.trim()) ?? 0;
    final minOrderMinor = Money.parseToMinor(_minOrder.text) ?? 0;
    final maxUses = int.tryParse(_maxUses.text.trim());

    final coupon = Coupon(
      code: _code.text.trim().toUpperCase(),
      type: _type,
      valueBps: _type == CouponType.percent ? (valueNumber * 100).round() : null,
      valueMinor: _type == CouponType.fixed ? (valueNumber * 100).round() : null,
      minOrderMinor: minOrderMinor,
      expiresAt: _expiresAt,
      maxUses: maxUses,
      usedCount: widget.coupon?.usedCount ?? 0,
      isActive: widget.coupon?.isActive ?? true,
    );

    if (_isEdit) {
      bloc.add(CouponsBoardUpdateRequested(coupon));
    } else {
      bloc.add(CouponsBoardCreateRequested(coupon));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

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
                _isEdit ? l10n.promosCouponEditTitle : l10n.promosCouponsAddAction,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.promosCouponCodeLabel,
                controller: _code,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
              ),
              if (!_isEdit) ...[
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<CouponType>(
                  segments: [
                    ButtonSegment(
                      value: CouponType.percent,
                      label: Text(l10n.promosCouponTypePercent),
                    ),
                    ButtonSegment(
                      value: CouponType.fixed,
                      label: Text(l10n.promosCouponTypeFixed),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (v) => setState(() => _type = v.first),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppTextField(
                label: _type == CouponType.percent
                    ? l10n.promosCouponValuePercentLabel
                    : l10n.promosCouponValueFixedLabel,
                controller: _value,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                    (v == null || double.tryParse(v.trim()) == null) ? l10n.validateRequired : null,
              ),
              AppTextField(
                label: l10n.promosCouponMinOrderLabel,
                controller: _minOrder,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              AppTextField(
                label: l10n.promosCouponMaxUsesLabel,
                controller: _maxUses,
                keyboardType: TextInputType.number,
                hintText: l10n.promosCouponMaxUsesHint,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _expiresAt == null
                            ? l10n.promosCouponNoExpiry
                            : DateFormat.yMMMd(languageCode).format(_expiresAt!),
                      ),
                    ),
                    TextButton(onPressed: _pickExpiry, child: Text(l10n.promosCouponPickExpiry)),
                    if (_expiresAt != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _expiresAt = null),
                      ),
                  ],
                ),
              ),
              AppButton(label: _isEdit ? l10n.actionSave : l10n.actionCreate, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
