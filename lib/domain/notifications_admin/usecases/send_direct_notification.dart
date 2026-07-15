import '../repositories/admin_notifications_repository.dart';

/// Thin pass-through.
class SendDirectNotification {
  const SendDirectNotification(this._repository);

  final AdminNotificationsRepository _repository;

  Future<void> call({
    required String uid,
    required String title,
    required String body,
  }) =>
      _repository.sendDirect(uid: uid, title: title, body: body);
}
