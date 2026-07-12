import 'package:flutter/material.dart';

import '../../../domain/admin/entities/admin_profile.dart';
import '../../../domain/admin/entities/permissions.dart';

/// One entry per console area. The nav shell builds its menu from this list,
/// filtered by [AdminProfile.can] — sections the staff member cannot use simply
/// do not render (Firestore rules + the Worker still enforce underneath; the
/// menu is convenience, never the security boundary).
class ConsoleSection {
  const ConsoleSection({
    required this.route,
    required this.icon,
    required this.labelKey,
    required this.requiredPerm,
  });

  final String route; // '/console', '/console/audit', …
  final IconData icon;
  final String labelKey; // l10n key name, resolved in the shell
  final String? requiredPerm; // null = any active staff (dashboard)
}

/// The console menu, in display order. Routes land across sessions 05–17; a
/// section is added here only once its route exists, so nothing in the menu
/// ever routes nowhere. Start = dashboard + audit; appended per session.
const consoleSections = <ConsoleSection>[
  ConsoleSection(
    route: '/console',
    icon: Icons.space_dashboard_outlined,
    labelKey: 'consoleNavDashboard',
    requiredPerm: null,
  ),
  ConsoleSection(
    route: '/console/audit',
    icon: Icons.receipt_long_outlined,
    labelKey: 'consoleNavAudit',
    requiredPerm: Permissions.auditlogsRead,
  ),
];

/// The sections a given staff member may see, in order. Empty for a non-staff
/// or inactive account (the shell should never be reached by one — the router
/// guards `/console` — but this keeps the menu correct if it is). Pure so the
/// filtering is unit-testable without pumping the widget tree.
List<ConsoleSection> visibleConsoleSections(AdminProfile? admin) {
  if (admin == null || !admin.isActive) return const [];
  return consoleSections
      .where((s) => s.requiredPerm == null || admin.can(s.requiredPerm!))
      .toList(growable: false);
}
