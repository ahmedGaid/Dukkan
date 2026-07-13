import '../../../domain/audit/entities/audit_entry.dart';

/// Parses an `/auditLogs/{id}` doc written by the Worker's `writeAudit`.
/// Fail-soft: a missing/blank field falls back to a safe default so a single
/// malformed entry never breaks the whole list. `createdAt` is an ISO-8601 UTC
/// string on the wire — parsed to [DateTime] here (epoch if unparseable).
class AuditEntryModel extends AuditEntry {
  const AuditEntryModel({
    required super.id,
    required super.actorUid,
    required super.action,
    required super.targetType,
    required super.targetId,
    required super.createdAt,
    super.before,
    super.after,
    super.reason,
    super.reported,
    super.ip,
  });

  factory AuditEntryModel.fromFirestore(String id, Map<String, dynamic> data) {
    return AuditEntryModel(
      id: id,
      actorUid: data['actorUid'] as String? ?? '',
      action: data['action'] as String? ?? '',
      targetType: data['targetType'] as String? ?? '',
      targetId: data['targetId'] as String? ?? '',
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      before: _asMap(data['before']),
      after: _asMap(data['after']),
      reason: data['reason'] as String?,
      reported: data['reported'] as bool? ?? false,
      ip: data['ip'] as String?,
    );
  }

  /// `before`/`after` may be a snapshot object, or (rarely) a scalar the Worker
  /// stored as-is. Keep it only when it's a map — the diff view needs keys.
  static Map<String, dynamic>? _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;
}
