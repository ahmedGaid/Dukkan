import 'package:flutter/material.dart';

import '../../../core/money.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Staff "cancel order" dialog (FC10) — a required reason plus an optional
/// COD refund note (a ledger note only; no money actually moves, the
/// customer never paid electronically).
Future<({String reason, int? refundNoteMinor})?> showStaffCancelDialog(BuildContext context) {
  return showDialog<({String reason, int? refundNoteMinor})>(
    context: context,
    builder: (_) => const _StaffCancelDialog(),
  );
}

class _StaffCancelDialog extends StatefulWidget {
  const _StaffCancelDialog();

  @override
  State<_StaffCancelDialog> createState() => _StaffCancelDialogState();
}

class _StaffCancelDialogState extends State<_StaffCancelDialog> {
  final _reasonCtrl = TextEditingController();
  final _refundCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _refundCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final canSubmit = _reasonCtrl.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text(l10n.actionCancelOrder),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.orderCancelConfirmBody, style: TextStyle(color: scheme.error)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.orderStaffReasonLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _refundCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.orderRefundNoteLabel,
                helperText: l10n.orderRefundNoteHelper,
              ),
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
              ? () => Navigator.of(context).pop((
                    reason: _reasonCtrl.text.trim(),
                    refundNoteMinor: Money.parseToMinor(_refundCtrl.text),
                  ))
              : null,
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          child: Text(l10n.actionCancelOrder),
        ),
      ],
    );
  }
}
