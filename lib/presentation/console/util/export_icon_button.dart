import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/admin/entities/permissions.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'export_action.dart';

/// Board export button (FC17 Task B) — hidden for a caller without
/// `reports.export`, the same convenience-gate every other console action
/// icon uses (Firestore rules stay the real boundary for the underlying
/// reads). [onExport] does the fetch + `exportCsv` call; this widget only
/// owns the permission check and the progress dialog.
class ExportIconButton extends StatelessWidget {
  const ExportIconButton({super.key, required this.onExport});

  final Future<void> Function(BuildContext context) onExport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final admin = context.watch<AuthBloc>().state.adminProfile;
    if (admin == null || !admin.can(Permissions.reportsExport)) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.download_outlined, size: 18),
      tooltip: l10n.consoleExportAction,
      onPressed: () => runExportWithProgress(context, () => onExport(context)),
    );
  }
}
