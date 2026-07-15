import '../repositories/admin_notifications_repository.dart';

/// Thin pass-through. Creates when [id] is null, else updates.
class SaveNotificationTemplate {
  const SaveNotificationTemplate(this._repository);

  final AdminNotificationsRepository _repository;

  Future<void> call({
    String? id,
    required String name,
    required String title,
    required String body,
  }) =>
      _repository.saveTemplate(id: id, name: name, title: title, body: body);
}
