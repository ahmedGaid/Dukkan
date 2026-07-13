import 'package:dukkan/domain/admin/entities/admin_profile.dart';
import 'package:dukkan/domain/admin/entities/permissions.dart';
import 'package:dukkan/domain/admin/entities/staff_role.dart';
import 'package:dukkan/presentation/console/shell/console_sections.dart';
import 'package:flutter_test/flutter_test.dart';

/// The console shell renders `visibleConsoleSections(admin)`; testing that pure
/// filter is the whole permission contract, without pumping a Firebase-backed
/// AuthBloc into a widget tree.
AdminProfile _admin({
  Set<String> perms = const {},
  bool isActive = true,
  StaffRole role = StaffRole.support,
}) =>
    AdminProfile(
      uid: 'u1',
      role: role,
      permissions: perms,
      isActive: isActive,
      rank: role.rank,
    );

void main() {
  group('visibleConsoleSections', () {
    test('non-staff (null profile) sees no sections', () {
      expect(visibleConsoleSections(null), isEmpty);
    });

    test('inactive staff sees no sections even with the wildcard', () {
      final sections = visibleConsoleSections(
        _admin(perms: {Permissions.all}, isActive: false),
      );
      expect(sections, isEmpty);
    });

    test('active staff always sees the dashboard (null-perm section)', () {
      final routes = visibleConsoleSections(_admin()).map((s) => s.route);
      expect(routes, contains('/console'));
    });

    test('audit is hidden without auditlogs.read', () {
      final routes = visibleConsoleSections(_admin()).map((s) => s.route);
      expect(routes, isNot(contains('/console/audit')));
    });

    test('audit appears with auditlogs.read', () {
      final routes = visibleConsoleSections(
        _admin(perms: {Permissions.auditlogsRead}),
      ).map((s) => s.route);
      expect(routes, contains('/console/audit'));
    });

    test('founder wildcard sees every registered section', () {
      final sections = visibleConsoleSections(
        _admin(perms: {Permissions.all}, role: StaffRole.founder),
      );
      expect(sections.length, consoleSections.length);
    });
  });

  group('consoleSectionForLocation (router guard resolves the perm)', () {
    test('exact route resolves its section', () {
      expect(consoleSectionForLocation('/console')?.route, '/console');
      expect(
        consoleSectionForLocation('/console/audit')?.requiredPerm,
        Permissions.auditlogsRead,
      );
    });

    test('a nested path resolves to the deepest matching section', () {
      expect(
        consoleSectionForLocation('/console/audit/e42')?.route,
        '/console/audit',
      );
    });

    test('an unknown console subpath falls back to the dashboard section '
        '(null perm ⇒ the guard never bounces it)', () {
      final s = consoleSectionForLocation('/console/unknown');
      expect(s?.route, '/console');
      expect(s?.requiredPerm, isNull);
    });

    test('the guard would bounce audit for staff lacking auditlogs.read', () {
      // Mirrors the router `_redirect` check: section.requiredPerm present and
      // not granted ⇒ bounce. Dashboard (null perm) is never bounced.
      final staff = _admin(); // no perms
      final audit = consoleSectionForLocation('/console/audit')!;
      final dashboard = consoleSectionForLocation('/console')!;
      expect(audit.requiredPerm != null && !staff.can(audit.requiredPerm!),
          isTrue);
      expect(dashboard.requiredPerm, isNull);
    });
  });
}
