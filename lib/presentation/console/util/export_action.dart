import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/injector.dart';
import '../../../data/admin/datasources/admin_api_datasource.dart';
import '../../../l10n/app_localizations.dart';
import 'csv_exporter.dart';

/// Shared "export current view to CSV" action for every board + the reports
/// page (FC17 Task B) — builds the file, reports one best-effort audit entry
/// (`report.export`), then surfaces the saved path as selectable text (no
/// share dep, per the FILE_17 spec). [rows] includes the header row; the
/// audited count excludes it.
Future<void> exportCsv(
  BuildContext context, {
  required String filenameBase,
  required List<List<String>> rows,
  required String auditTargetType,
  bool capped = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final csv = CsvExporter.toCsv(rows);
  final name = '${filenameBase}_${DateTime.now().toIso8601String().split('T').first}.csv';
  final path = await CsvExporter.saveCsv(name, csv);
  unawaited(sl<AdminApiDataSource>().reportAudit(
    action: 'report.export',
    targetType: auditTargetType,
    targetId: 'bulk',
    after: {'entity': auditTargetType, 'count': rows.length - 1},
  ));
  if (!context.mounted) return;
  final message =
      capped ? '${l10n.consoleExportSavedTo(path)}\n${l10n.consoleExportCapped}' : l10n.consoleExportSavedTo(path);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: SelectableText(message),
    duration: const Duration(seconds: 6),
  ));
}

/// Runs [task] behind a non-dismissible progress dialog — the boards' export
/// buttons paginate up to 1000 docs, which can take a moment.
Future<void> runExportWithProgress(BuildContext context, Future<void> Function() task) async {
  final l10n = AppLocalizations.of(context)!;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4)),
          const SizedBox(width: 16),
          Text(l10n.consoleExportInProgress),
        ],
      ),
    ),
  );
  try {
    await task();
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}
