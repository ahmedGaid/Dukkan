import 'package:dukkan/domain/admin/entities/admin_profile.dart';
import 'package:dukkan/domain/admin/entities/permissions.dart';
import 'package:dukkan/domain/admin/entities/staff_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminProfile.can (Founder Console RBAC)', () {
    AdminProfile profile({
      Set<String> permissions = const {},
      bool isActive = true,
      StaffRole role = StaffRole.admin,
    }) =>
        AdminProfile(
          uid: 'u1',
          role: role,
          permissions: permissions,
          isActive: isActive,
          rank: role.rank,
        );

    test('grants an exact permission it holds', () {
      expect(
        profile(permissions: {Permissions.financeRead})
            .can(Permissions.financeRead),
        isTrue,
      );
    });

    test('denies a permission it does not hold', () {
      expect(
        profile(permissions: {Permissions.ordersRead})
            .can(Permissions.financeRead),
        isFalse,
      );
    });

    test('the wildcard grants any permission (founder)', () {
      final founder =
          profile(permissions: {Permissions.all}, role: StaffRole.founder);
      expect(founder.can(Permissions.financeRead), isTrue);
      expect(founder.can(Permissions.systemImpersonate), isTrue);
    });

    test('an inactive admin can do nothing, even with the wildcard', () {
      expect(
        profile(permissions: {Permissions.all}, isActive: false)
            .can(Permissions.financeRead),
        isFalse,
      );
    });
  });

  group('StaffRole rank ordering', () {
    test('tiers ascend support < moderator < admin < founder', () {
      expect(StaffRole.support.rank, 40);
      expect(StaffRole.moderator.rank, 60);
      expect(StaffRole.admin.rank, 80);
      expect(StaffRole.founder.rank, 100);
    });
  });
}
