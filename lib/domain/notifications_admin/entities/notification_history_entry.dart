import 'package:equatable/equatable.dart';

/// One `/notifications/{id}` history doc, Worker-written only (FC13, Task B)
/// — same immutability shape as `AuditEntry`. [audience] is set for a
/// `broadcast` [kind], [targetUid] for a `direct` one; never both.
class NotificationHistoryEntry extends Equatable {
  const NotificationHistoryEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.sentBy,
    required this.sentAt,
    required this.status,
    this.audience,
    this.targetUid,
    this.error,
  });

  final String id;

  /// `broadcast` | `direct`.
  final String kind;
  final String title;
  final String body;
  final String sentBy;
  final DateTime sentAt;

  /// `sent` | `failed` | `skipped` (direct send to a token-less user).
  final String status;

  /// `customers` | `owners` | `couriers` | `all` — only for [kind] `broadcast`.
  final String? audience;

  /// Only for [kind] `direct`.
  final String? targetUid;
  final String? error;

  @override
  List<Object?> get props =>
      [id, kind, title, body, sentBy, sentAt, status, audience, targetUid, error];
}
