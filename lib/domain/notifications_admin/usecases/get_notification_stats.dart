import '../entities/notification_stats.dart';
import '../repositories/admin_notifications_repository.dart';

/// Thin pass-through.
class GetNotificationStats {
  const GetNotificationStats(this._repository);

  final AdminNotificationsRepository _repository;

  Future<NotificationStats> call() => _repository.getStats();
}
