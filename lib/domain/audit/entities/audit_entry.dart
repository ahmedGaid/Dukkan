import 'package:equatable/equatable.dart';

/// One immutable entry in the platform audit trail (`/auditLogs`). Written ONLY
/// by the Worker (`writeAudit`) — clients can never create/update/delete one
/// (Firestore rule `allow write: if false`). The console reads them here.
///
/// [reported] distinguishes the two trust levels the Worker records:
///   * `false` — the mutation itself ran server-side (Worker-routed), so the
///     entry is authoritative.
///   * `true`  — a client-direct, rules-guarded mutation self-reported via
///     `POST /admin/audit`; best-effort by nature (the actor is still taken
///     from the verified token, never the request body).
///
/// [before]/[after] are field snapshots captured around the change; only the
/// keys that actually differ are shown in the console diff. Either may be null
/// (a create has no `before`, a delete no `after`).
class AuditEntry extends Equatable {
  const AuditEntry({
    required this.id,
    required this.actorUid,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
    this.before,
    this.after,
    this.reason,
    this.reported = false,
    this.ip,
  });

  final String id;
  final String actorUid;

  /// Dotted operation code, e.g. `order.forceStatus`, `user.disable`. The
  /// known set for the filter dropdowns lives in `audit_actions.dart`.
  final String action;

  /// The kind of thing acted on, e.g. `order`, `user`, `shop`.
  final String targetType;
  final String targetId;

  /// Parsed from the Worker's ISO-8601 UTC string. String order == time order
  /// for that format, so Firestore can `orderBy('createdAt')` on the raw value.
  final DateTime createdAt;

  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final String? reason;
  final bool reported;
  final String? ip;

  @override
  List<Object?> get props => [
        id,
        actorUid,
        action,
        targetType,
        targetId,
        createdAt,
        before,
        after,
        reason,
        reported,
        ip,
      ];
}
