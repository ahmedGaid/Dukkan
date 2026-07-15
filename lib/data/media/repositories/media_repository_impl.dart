import '../../../core/config/app_config.dart';
import '../../../domain/media/entities/media_object.dart';
import '../../../domain/media/entities/media_folder_stats.dart';
import '../../../domain/media/entities/media_page.dart';
import '../../../domain/media/entities/media_reference.dart';
import '../../../domain/media/entities/media_stats.dart';
import '../../../domain/media/repositories/media_repository.dart';
import '../../admin/datasources/admin_api_datasource.dart';
import '../datasources/media_reference_remote_datasource.dart';

/// Browse/stats/delete are Worker-routed (`/admin/media/*` — R2 isn't
/// Firestore, there is no client-direct path here, unlike most other
/// sections); the Worker audits `delete` server-side, so no client-side
/// [AdminApiDataSource.reportAudit] call, same contract as
/// `AdminNotificationsRepositoryImpl`'s sends.
class MediaRepositoryImpl implements MediaRepository {
  MediaRepositoryImpl(this._api, this._references);

  final AdminApiDataSource _api;
  final MediaReferenceRemoteDataSource _references;

  // Defensive only — the Worker has no hard cap on `list` pagination and the
  // bucket is expected to stay small; this just stops a runaway loop from
  // ever hanging the finder tabs.
  static const _maxListAllPages = 500;

  @override
  Future<MediaPage> list({String? folder, String? cursor}) async {
    final res = await _api.post('media/list', {
      if (folder != null && folder.isNotEmpty) 'prefix': '$folder/',
      'cursor': ?cursor,
    });
    return MediaPage(
      objects: _parseObjects(res['objects']),
      cursor: res['cursor'] as String?,
    );
  }

  @override
  Future<List<MediaObject>> listAll() async {
    final all = <MediaObject>[];
    String? cursor;
    for (var i = 0; i < _maxListAllPages; i++) {
      final page = await list(cursor: cursor);
      all.addAll(page.objects);
      cursor = page.cursor;
      if (cursor == null) break;
    }
    return all;
  }

  @override
  Future<MediaStats> stats() async {
    final res = await _api.post('media/stats', const {});
    final byFolderRaw = (res['byFolder'] as Map?)?.cast<String, dynamic>() ?? const {};
    return MediaStats(
      count: (res['count'] as num?)?.toInt() ?? 0,
      totalBytes: (res['totalBytes'] as num?)?.toInt() ?? 0,
      truncated: res['truncated'] as bool? ?? false,
      byFolder: {
        for (final entry in byFolderRaw.entries)
          entry.key: MediaFolderStats(
            count: ((entry.value as Map)['count'] as num?)?.toInt() ?? 0,
            bytes: ((entry.value as Map)['bytes'] as num?)?.toInt() ?? 0,
          ),
      },
    );
  }

  @override
  Future<void> delete(List<String> keys) => _api.post('media/delete', {'keys': keys});

  @override
  Future<List<MediaReference>> getReferences() => _references.getReferences();

  List<MediaObject> _parseObjects(Object? raw) {
    final base = AppConfig.mediaPublicBaseUrl.replaceFirst(RegExp(r'/$'), '');
    return ((raw as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((o) => MediaObject(
              key: o['key'] as String,
              size: (o['size'] as num?)?.toInt() ?? 0,
              uploaded: DateTime.parse(o['uploaded'] as String),
              url: '$base/${o['key']}',
            ))
        .toList(growable: false);
  }
}
