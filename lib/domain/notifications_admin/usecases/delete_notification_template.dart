import '../repositories/admin_notifications_repository.dart';

/// Thin pass-through.
class DeleteNotificationTemplate {
  const DeleteNotificationTemplate(this._repository);

  final AdminNotificationsRepository _repository;

  Future<void> call(String id) => _repository.deleteTemplate(id);
}
