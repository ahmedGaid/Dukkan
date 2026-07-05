import '../../../domain/notifications/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remote);

  final NotificationRemoteDataSource _remote;

  @override
  Future<void> notifyOrderEvent({
    required String orderId,
    required NotificationEventType type,
    required String title,
    required String body,
  }) =>
      _remote.notify(orderId: orderId, type: type.wire, title: title, body: body);
}
