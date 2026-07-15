import '../entities/notification_history_page.dart';
import '../entities/notification_stats.dart';
import '../entities/notification_template.dart';

/// Founder Console notification center (FC13). Sends are Worker-routed
/// (`/admin/notify/*` — the Worker holds the FCM service account); history
/// reads and template CRUD are Firestore-direct (gated by
/// `notifications.send` in the rules).
abstract class AdminNotificationsRepository {
  /// `audience` is `customers` | `owners` | `couriers` | `all`.
  Future<void> sendBroadcast({
    required String audience,
    required String title,
    required String body,
  });

  Future<void> sendDirect({
    required String uid,
    required String title,
    required String body,
  });

  /// Newest first. [cursor] is the previous page's last entry `sentAt`
  /// (ISO-8601 UTC), same pass-the-timestamp-back contract as `AuditRepository`.
  Future<NotificationHistoryPage> getHistory({String? cursor});

  Future<NotificationStats> getStats();

  Future<List<NotificationTemplate>> getTemplates();

  /// Creates when [id] is null, else updates that template's fields.
  Future<void> saveTemplate({
    String? id,
    required String name,
    required String title,
    required String body,
  });

  Future<void> deleteTemplate(String id);
}
