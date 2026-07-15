import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/notifications_admin/entities/notification_history_entry.dart';

/// Parses a `/notifications/{id}` doc written by the Worker's
/// `writeNotificationHistory`. Fail-soft, same contract as `AuditEntryModel`.
class NotificationHistoryEntryModel extends NotificationHistoryEntry {
  const NotificationHistoryEntryModel({
    required super.id,
    required super.kind,
    required super.title,
    required super.body,
    required super.sentBy,
    required super.sentAt,
    required super.status,
    super.audience,
    super.targetUid,
    super.error,
  });

  factory NotificationHistoryEntryModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final sentAt = data['sentAt'];
    return NotificationHistoryEntryModel(
      id: id,
      kind: data['kind'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      sentBy: data['sentBy'] as String? ?? '',
      sentAt: sentAt is Timestamp
          ? sentAt.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      status: data['status'] as String? ?? 'failed',
      audience: data['audience'] as String?,
      targetUid: data['targetUid'] as String?,
      error: data['error'] as String?,
    );
  }
}
