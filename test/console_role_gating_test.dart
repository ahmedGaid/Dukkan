// FILE_18 Task B, client half — the console menu each SEEDED staff role gets.
//
// `console_shell_test.dart` already proves `visibleConsoleSections` filters on
// permissions using hand-made profiles. This file is the other half of that
// promise: it pins the filter against the permission sets the seed actually
// writes to `/roles`, so the three sources named in `Permissions`' doc comment
// (constants / rules / seed) cannot drift apart silently. Task B checks the same
// thing by hand on a live console; asserting it here means a wrong role set
// fails a gate long before anyone signs in as support staff.
import 'package:dukkan/dev/seed.dart';
import 'package:dukkan/domain/admin/entities/admin_profile.dart';
import 'package:dukkan/domain/admin/entities/permissions.dart';
import 'package:dukkan/domain/admin/entities/staff_role.dart';
import 'package:dukkan/presentation/console/shell/console_sections.dart';
import 'package:flutter_test/flutter_test.dart';

AdminProfile _profile(StaffRole role, List<String> perms) => AdminProfile(
  uid: 'staff-1',
  role: role,
  permissions: perms.toSet(),
  isActive: true,
  rank: role.rank,
);

List<String> _routesFor(StaffRole role, List<String> perms) =>
    visibleConsoleSections(_profile(role, perms)).map((s) => s.route).toList();

void main() {
  group('seeded support role', () {
    final routes = _routesFor(StaffRole.support, supportRolePermissions);

    test('sees exactly dashboard, users and orders', () {
      expect(routes, ['/console', '/console/users', '/console/orders']);
    });

    // The plan calls this one out explicitly: support must not reach the audit
    // trail, and must not see anything that mutates the platform itself.
    test('cannot see audit, settings, devtools, promos or media', () {
      expect(
        routes,
        isNot(
          anyElement(
            isIn([
              '/console/audit',
              '/console/settings',
              '/console/devtools',
              '/console/promos',
              '/console/media',
            ]),
          ),
        ),
      );
    });

    test('holds no permission beyond reading users and handling orders', () {
      expect(supportRolePermissions.toSet(), {
        Permissions.usersRead,
        Permissions.ordersRead,
        Permissions.ordersUpdate,
      });
    });
  });

  group('seeded moderator role', () {
    final routes = _routesFor(StaffRole.moderator, moderatorRolePermissions);

    test('sees content and order sections, nothing destructive', () {
      expect(routes, [
        '/console',
        '/console/shops',
        '/console/products',
        '/console/orders',
        '/console/taxonomy',
      ]);
    });
  });

  group('seeded admin role', () {
    final routes = _routesFor(StaffRole.admin, adminRolePermissions);

    // "admin = everything except the three founder-reserved powers" — of those
    // three, only settings.edit gates a console section, so settings is the one
    // menu entry an admin must never see.
    test('sees every section except platform settings', () {
      final all = consoleSections.map((s) => s.route).toList();
      expect(routes, all.where((r) => r != '/console/settings').toList());
    });

    test('holds neither of the two founder-reserved powers without a section', () {
      expect(adminRolePermissions, isNot(contains(Permissions.adminsManage)));
      expect(adminRolePermissions, isNot(contains(Permissions.systemImpersonate)));
      expect(adminRolePermissions, isNot(contains(Permissions.settingsEdit)));
    });
  });

  group('section table invariants', () {
    test('every gate names a real permission', () {
      for (final section in consoleSections) {
        if (section.requiredPerm == null) continue;
        expect(
          Permissions.values,
          contains(section.requiredPerm),
          reason: '${section.route} is gated on an unknown permission',
        );
      }
    });

    // A section gated on a permission no seeded role can hold would be founder-
    // only forever — fine for settings (deliberate), a bug anywhere else.
    test('only settings is unreachable for the admin role', () {
      final adminPerms = adminRolePermissions.toSet();
      final founderOnly = consoleSections
          .where((s) => s.requiredPerm != null && !adminPerms.contains(s.requiredPerm))
          .map((s) => s.route)
          .toList();
      expect(founderOnly, ['/console/settings']);
    });
  });
}
