import '../entities/notification_template.dart';
import '../repositories/admin_notifications_repository.dart';

/// Thin pass-through.
class GetNotificationTemplates {
  const GetNotificationTemplates(this._repository);

  final AdminNotificationsRepository _repository;

  Future<List<NotificationTemplate>> call() => _repository.getTemplates();
}
