import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dukkan/data/admin/models/auth_lookup_model.dart';
import 'package:dukkan/data/admin/models/managed_user_model.dart';
import 'package:dukkan/domain/auth/entities/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManagedUserModel.fromFirestore', () {
    test('parses a full doc', () {
      final createdAt = DateTime.utc(2026, 7, 1);
      final model = ManagedUserModel.fromFirestore('u1', {
        'name': 'Sara',
        'email': 'sara@example.com',
        'role': 'owner',
        'phone': '0100000000',
        'status': 'suspended',
        'deleted': false,
        'createdAt': Timestamp.fromDate(createdAt),
      });

      expect(model.uid, 'u1');
      expect(model.role, UserRole.owner);
      expect(model.status, 'suspended');
      // Timestamp.toDate() returns local time — compare in UTC to stay
      // timezone-independent.
      expect(model.createdAt?.toUtc(), createdAt);
    });

    test('defaults missing moderation fields to active/not-deleted', () {
      final model = ManagedUserModel.fromFirestore('u2', {
        'name': 'Old User',
        'email': 'old@example.com',
        'role': 'customer',
      });

      expect(model.status, 'active');
      expect(model.deleted, isFalse);
      expect(model.createdAt, isNull);
    });

    test('an unknown role wire string falls back to customer', () {
      final model = ManagedUserModel.fromFirestore('u3', {
        'name': 'X',
        'email': 'x@example.com',
        'role': 'staff-legacy-value',
      });

      expect(model.role, UserRole.customer);
    });
  });

  group('AuthLookupModel.fromJson', () {
    test('parses epoch-millisecond strings into DateTime', () {
      final model = AuthLookupModel.fromJson({
        'email': 'sara@example.com',
        'emailVerified': true,
        'disabled': false,
        'lastLoginAt': '1735689600000',
        'createdAt': '1704067200000',
      });

      expect(model.emailVerified, isTrue);
      expect(model.lastLoginAt, DateTime.fromMillisecondsSinceEpoch(1735689600000));
      expect(model.createdAt, DateTime.fromMillisecondsSinceEpoch(1704067200000));
    });

    test('missing/unparseable timestamps fall back to null, not a crash', () {
      final model = AuthLookupModel.fromJson({
        'emailVerified': false,
        'disabled': true,
      });

      expect(model.email, isNull);
      expect(model.lastLoginAt, isNull);
      expect(model.createdAt, isNull);
    });
  });
}
