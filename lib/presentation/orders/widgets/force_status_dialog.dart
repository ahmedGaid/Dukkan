import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/order/entities/order_status.dart';
import '../../../l10n/app_localizations.dart';
import '../order_status_view.dart';

/// Staff "force status" dialog (FC10) — a status dropdown plus a required
/// reason. Every correction is audited server-side with this reason, so the
/// dialog blocks submit until one is typed (mirrors the shop reject-reason
/// requirement, `ShopDetailPage`).
Future<({OrderStatus status, String reason})?> showForceStatusDialog(
  BuildContext context,
  OrderStatus current,
) {
  return showDialog<({OrderStatus status, String reason})>(
    context: context,
    builder: (_) => _ForceStatusDialog(current: current),
  );
}

class _ForceStatusDialog extends StatefulWidget {
  const _ForceStatusDialog({required this.current});

  final OrderStatus current;

  @override
  State<_ForceStatusDialog> createState() => _ForceStatusDialogState();
}

class _ForceStatusDialogState extends State<_ForceStatusDialog> {
  late OrderStatus _target = widget.current;
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final canSubmit = _reasonCtrl.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text(l10n.orderForceStatusAction),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.orderForceStatusWarning,
              style: TextStyle(color: scheme.error),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<OrderStatus>(
              initialValue: _target,
              decoration: InputDecoration(labelText: l10n.orderForceStatusLabel),
              items: [
                for (final status in OrderStatus.values)
                  DropdownMenuItem(
                    value: status,
                    child: Text(orderStatusView(l10n, status).label),
                  ),
              ],
              onChanged: (v) => setState(() => _target = v ?? _target),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.orderStaffReasonLabel),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: canSubmit
              ? () => Navigator.of(context)
                  .pop((status: _target, reason: _reasonCtrl.text.trim()))
              : null,
          child: Text(l10n.orderForceStatusAction),
        ),
      ],
    );
  }
}
