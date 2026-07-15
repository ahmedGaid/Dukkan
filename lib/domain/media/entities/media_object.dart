import 'package:equatable/equatable.dart';

/// One R2 object as the Worker's `/admin/media/list` reports it. [url] is
/// composed client-side (`AppConfig.mediaPublicBaseUrl` + [key]) — the Worker
/// returns bare keys, unlike `/upload`'s response.
class MediaObject extends Equatable {
  const MediaObject({
    required this.key,
    required this.size,
    required this.uploaded,
    required this.url,
  });

  final String key;
  final int size;
  final DateTime uploaded;
  final String url;

  /// The `{folder}` segment of `{folder}/{uid}/{uuid}.{ext}` (see
  /// `handleUpload` in `worker/src/index.js`).
  String get folder {
    final i = key.indexOf('/');
    return i < 0 ? key : key.substring(0, i);
  }

  @override
  List<Object?> get props => [key, size, uploaded, url];
}
