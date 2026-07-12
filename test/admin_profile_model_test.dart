import 'package:dukkan/data/admin/models/admin_profile_model.dart';
import 'package:dukkan/domain/admin/entities/permissions.dart';
import 'package:dukkan/domain/admin/entities/staff_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminProfileModel.fromFirestore (fail-closed parsing)', () {
    test('an empty doc defaults to the least-privileged, inactive profile', () {
      final m = AdminProfileModel.fromFirestore('u1', {});
      expect(m.uid, 'u1');
      expect(m.role, StaffRole.support);
      expect(m.permissions, isEmpty);
      expect(m.isActive, isFalse);
      expect(m.rank, 0);
    });

    test('a known active role parses with its permissions', () {
      final m = AdminProfileModel.fromFirestore('f1', {
        'role': 'founder',
        'permissions': [Permissions.all],
        'isActive': true,
        'rank': 100,
      });
      expect(m.role, StaffRole.founder);
      expect(m.permissions, {Permissions.all});
      expect(m.isActive, isTrue);
      expect(m.rank, 100);
      expect(m.can(Permissions.financeRead), isTrue);
    });

    test('an unknown role string fails closed to inactive support', () {
      final m = AdminProfileModel.fromFirestore('x1', {
        'role': 'superuser',
        'permissions': [Permissions.all],
        'isActive': true, // ignored — an untrusted role can't be active
        'rank': 100,
      });
      expect(m.role, StaffRole.support);
      expect(m.isActive, isFalse);
      expect(m.can(Permissions.financeRead), isFalse);
    });

    test('a known role missing isActive stays inactive (fail-closed default)',
        () {
      final m = AdminProfileModel.fromFirestore('a1', {
        'role': 'admin',
        'permissions': [Permissions.usersRead],
      });
      expect(m.role, StaffRole.admin);
      expect(m.isActive, isFalse);
    });
  });
}
