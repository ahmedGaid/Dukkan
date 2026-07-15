import 'dart:async';

import '../../../domain/admin/repositories/admin_settings_repository.dart';
import '../datasources/admin_api_datasource.dart';
import '../datasources/admin_settings_remote_datasource.dart';

class AdminSettingsRepositoryImpl implements AdminSettingsRepository {
  AdminSettingsRepositoryImpl(this._remote, this._api);

  final AdminSettingsRemoteDataSource _remote;
  final AdminApiDataSource _api;

  @override
  Future<void> updateConfig({
    required Map<String, dynamic> fields,
    required Map<String, dynamic> before,
    required Map<String, dynamic> after,
  }) async {
    await _remote.patchConfig(fields);
    unawaited(_api.reportAudit(
      action: 'settings.update',
      targetType: 'config',
      targetId: 'platform',
      before: before.isEmpty ? null : before,
      after: after.isEmpty ? null : after,
    ));
  }

  @override
  Future<void> setFlag({required String key, required bool value}) async {
    await _remote.setFlag(key, value);
    unawaited(_api.reportAudit(
      action: 'flags.update',
      targetType: 'config',
      targetId: 'flags',
      after: {key: value},
    ));
  }

  @override
  Future<void> deleteFlag(String key) async {
    await _remote.deleteFlag(key);
    unawaited(_api.reportAudit(
      action: 'flags.update',
      targetType: 'config',
      targetId: 'flags',
      before: {key: 'deleted'},
    ));
  }
}
