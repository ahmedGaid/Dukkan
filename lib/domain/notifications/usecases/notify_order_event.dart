import '../repositories/notification_repository.dart';

class NotifyOrderEvent {
  const NotifyOrderEvent(this._repository);

  final NotificationRepository _repository;

  Future<void> call({
    required String orderId,
    required NotificationEventType type,
    required String title,
    required String body,
  }) =>
      _repository.notifyOrderEvent(
        orderId: orderId,
        type: type,
        title: title,
        body: body,
      );
}
