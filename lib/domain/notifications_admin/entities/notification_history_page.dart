import 'package:equatable/equatable.dart';

import 'notification_history_entry.dart';

/// One cursor-paginated page of the notification history list — same shape
/// as `AuditPage`.
class NotificationHistoryPage extends Equatable {
  const NotificationHistoryPage({required this.entries, required this.hasMore});

  final List<NotificationHistoryEntry> entries;
  final bool hasMore;

  @override
  List<Object?> get props => [entries, hasMore];
}
