import '../entities/notification_history_page.dart';
import '../repositories/admin_notifications_repository.dart';

/// Thin pass-through.
class GetNotificationHistory {
  const GetNotificationHistory(this._repository);

  final AdminNotificationsRepository _repository;

  Future<NotificationHistoryPage> call({String? cursor}) =>
      _repository.getHistory(cursor: cursor);
}
