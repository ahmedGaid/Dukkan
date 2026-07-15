import 'dart:async';

import '../../../domain/notifications_admin/entities/notification_history_page.dart';
import '../../../domain/notifications_admin/entities/notification_stats.dart';
import '../../../domain/notifications_admin/entities/notification_template.dart';
import '../../../domain/notifications_admin/repositories/admin_notifications_repository.dart';
import '../../admin/datasources/admin_api_datasource.dart';
import '../datasources/admin_notifications_remote_datasource.dart';

/// Sends are Worker-routed (`/admin/notify/*` — the Worker audits them
/// server-side, so no client-side [AdminApiDataSource.reportAudit] here,
/// same contract as `AdminOrdersRepositoryImpl`'s corrections). History reads
/// and template CRUD are Firestore-direct; template writes DO self-report
/// (mirrors `AdminTaxonomyRepositoryImpl`).
class AdminNotificationsRepositoryImpl implements AdminNotificationsRepository {
  AdminNotificationsRepositoryImpl(this._remote, this._api);

  final AdminNotificationsRemoteDataSource _remote;
  final AdminApiDataSource _api;

  @override
  Future<void> sendBroadcast({
    required String audience,
    required String title,
    required String body,
  }) =>
      _api.post('notify/broadcast', {'audience': audience, 'title': title, 'body': body});

  @override
  Future<void> sendDirect({
    required String uid,
    required String title,
    required String body,
  }) =>
      _api.post('notify/user', {'uid': uid, 'title': title, 'body': body});

  @override
  Future<NotificationHistoryPage> getHistory({String? cursor}) =>
      _remote.getHistory(cursor: cursor);

  @override
  Future<NotificationStats> getStats() => _remote.getStats();

  @override
  Future<List<NotificationTemplate>> getTemplates() => _remote.getTemplates();

  @override
  Future<void> saveTemplate({
    String? id,
    required String name,
    required String title,
    required String body,
  }) async {
    final fields = {'name': name, 'title': title, 'body': body};
    if (id == null) {
      await _remote.createTemplate(fields);
    } else {
      await _remote.patchTemplate(id, fields);
    }
    unawaited(_api.reportAudit(
      action: 'template.save',
      targetType: 'notificationTemplate',
      targetId: id ?? name,
      after: fields,
    ));
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _remote.deleteTemplate(id);
    unawaited(_api.reportAudit(
      action: 'template.delete',
      targetType: 'notificationTemplate',
      targetId: id,
    ));
  }
}
