import '../repositories/admin_notifications_repository.dart';

/// Thin pass-through.
class SendBroadcastNotification {
  const SendBroadcastNotification(this._repository);

  final AdminNotificationsRepository _repository;

  Future<void> call({
    required String audience,
    required String title,
    required String body,
  }) =>
      _repository.sendBroadcast(audience: audience, title: title, body: body);
}
