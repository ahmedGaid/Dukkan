import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/empty_state.dart';

/// The console home. A designed placeholder this session — Session 5 replaces
/// the body with live platform stats, recent activity, and quick actions.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.insights_outlined,
      title: l10n.consoleTitle,
      message: l10n.consoleDashboardSubtitle,
    );
  }
}
