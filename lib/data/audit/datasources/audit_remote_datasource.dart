import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/audit/entities/audit_filter.dart';
import '../../../domain/audit/entities/audit_page.dart';
import '../models/audit_entry_model.dart';

/// Reads the immutable `/auditLogs` trail, newest first, in pages of
/// [pageSize]. Each non-null [AuditFilter] field adds a `where`; [from]/[to]
/// bound `createdAt` (ISO-8601 UTC strings, so lexical order == time order).
/// Pagination is value-based on `createdAt` — no `DocumentSnapshot` leaks into
/// the domain — so the caller just passes the last entry's timestamp back in.
class AuditRemoteDataSource {
  AuditRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const pageSize = 30;

  Future<AuditPage> getEntries({
    required AuditFilter filter,
    String? afterCreatedAt,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _firestore.collection('auditLogs');

      if (filter.action != null) {
        q = q.where('action', isEqualTo: filter.action);
      }
      if (filter.targetType != null) {
        q = q.where('targetType', isEqualTo: filter.targetType);
      }
      if (filter.actorUid != null) {
        q = q.where('actorUid', isEqualTo: filter.actorUid);
      }
      if (filter.targetId != null) {
        q = q.where('targetId', isEqualTo: filter.targetId);
      }
      if (filter.from != null) {
        q = q.where('createdAt',
            isGreaterThanOrEqualTo: filter.from!.toUtc().toIso8601String());
      }
      if (filter.to != null) {
        q = q.where('createdAt',
            isLessThanOrEqualTo: filter.to!.toUtc().toIso8601String());
      }

      q = q.orderBy('createdAt', descending: true);
      if (afterCreatedAt != null) {
        q = q.startAfter([afterCreatedAt]);
      }
      q = q.limit(pageSize);

      final snap = await q.get();
      final entries = snap.docs
          .map((d) => AuditEntryModel.fromFirestore(d.id, d.data()))
          .toList(growable: false);

      // A full page means there is (probably) another; a short page is the end.
      return AuditPage(entries: entries, hasMore: entries.length == pageSize);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
