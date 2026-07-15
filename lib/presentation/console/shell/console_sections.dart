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
  ConsoleSection(
    route: '/console/users',
    icon: Icons.people_outline,
    labelKey: 'consoleNavUsers',
    requiredPerm: Permissions.usersRead,
  ),
  ConsoleSection(
    route: '/console/shops',
    icon: Icons.storefront_outlined,
    labelKey: 'consoleNavShops',
    requiredPerm: Permissions.shopsUpdate,
  ),
  ConsoleSection(
    route: '/console/products',
    icon: Icons.inventory_2_outlined,
    labelKey: 'consoleNavProducts',
    requiredPerm: Permissions.productsUpdate,
  ),
  ConsoleSection(
    route: '/console/orders',
    icon: Icons.receipt_long_outlined,
    labelKey: 'consoleNavOrders',
    requiredPerm: Permissions.ordersRead,
  ),
  ConsoleSection(
    route: '/console/taxonomy',
    icon: Icons.category_outlined,
    labelKey: 'consoleNavTaxonomy',
    requiredPerm: Permissions.taxonomyEdit,
  ),
  ConsoleSection(
    route: '/console/geo',
    icon: Icons.map_outlined,
    labelKey: 'consoleNavGeo',
    requiredPerm: Permissions.geoEdit,
  ),
  ConsoleSection(
    route: '/console/drivers',
    icon: Icons.delivery_dining_outlined,
    labelKey: 'consoleNavDrivers',
    requiredPerm: Permissions.driversManage,
  ),
  ConsoleSection(
    route: '/console/settings',
    icon: Icons.settings_outlined,
    labelKey: 'consoleNavSettings',
    requiredPerm: Permissions.settingsEdit,
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

/// The console section a [location] belongs to — an exact route match, else the
/// deepest section whose route prefixes it (nested pages land in later
/// sessions). Null when nothing matches. The router guard uses this to enforce
/// each section's [ConsoleSection.requiredPerm] on a direct/deep-link
/// navigation (the menu already hides sections a staff member cannot use, but
/// the URL must be guarded too — UI is never the only gate).
ConsoleSection? consoleSectionForLocation(String location) {
  ConsoleSection? best;
  for (final s in consoleSections) {
    if (s.route == location) return s;
    if (location.startsWith('${s.route}/') &&
        (best == null || s.route.length > best.route.length)) {
      best = s;
    }
  }
  return best;
}
