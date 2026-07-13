import 'package:dukkan/data/audit/models/audit_entry_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuditEntryModel.fromFirestore (fail-soft parsing)', () {
    test('a full doc parses every field', () {
      final m = AuditEntryModel.fromFirestore('e1', {
        'actorUid': 'founder-uid',
        'action': 'order.forceStatus',
        'targetType': 'order',
        'targetId': 'ord-42',
        'before': {'status': 'pending'},
        'after': {'status': 'delivered'},
        'reason': 'stuck order',
        'reported': false,
        'ip': '197.0.0.1',
        'createdAt': '2026-07-13T10:20:30.123Z',
      });

      expect(m.id, 'e1');
      expect(m.actorUid, 'founder-uid');
      expect(m.action, 'order.forceStatus');
      expect(m.targetType, 'order');
      expect(m.targetId, 'ord-42');
      expect(m.before!['status'], 'pending');
      expect(m.after!['status'], 'delivered');
      expect(m.reason, 'stuck order');
      expect(m.reported, isFalse);
      expect(m.ip, '197.0.0.1');
      expect(
        m.createdAt.toUtc(),
        DateTime.utc(2026, 7, 13, 10, 20, 30, 123),
      );
    });

    test('an empty doc falls back to safe defaults', () {
      final m = AuditEntryModel.fromFirestore('e2', {});
      expect(m.actorUid, '');
      expect(m.action, '');
      expect(m.targetType, '');
      expect(m.targetId, '');
      expect(m.before, isNull);
      expect(m.after, isNull);
      expect(m.reason, isNull);
      expect(m.reported, isFalse);
      expect(m.ip, isNull);
      expect(m.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('a non-map before/after is dropped (diff view needs keys)', () {
      final m = AuditEntryModel.fromFirestore('e3', {
        'before': 'was a plain string',
        'after': 42,
      });
      expect(m.before, isNull);
      expect(m.after, isNull);
    });

    test('createdAt round-trips to the exact stored ISO string (the paging '
        'cursor reproduces it)', () {
      const iso = '2026-07-13T09:00:00.000Z';
      final m = AuditEntryModel.fromFirestore('e4', {'createdAt': iso});
      expect(m.createdAt.toUtc().toIso8601String(), iso);
    });
  });
}
