import 'package:equatable/equatable.dart';

import 'media_folder_stats.dart';

/// Whole-bucket totals from `/admin/media/stats` (a server-side pagination
/// loop, capped at 10k objects — [truncated] is the honest flag for "there
/// are more, this total is a floor, not the real total").
class MediaStats extends Equatable {
  const MediaStats({
    required this.count,
    required this.totalBytes,
    required this.byFolder,
    required this.truncated,
  });

  final int count;
  final int totalBytes;
  final Map<String, MediaFolderStats> byFolder;
  final bool truncated;

  @override
  List<Object?> get props => [count, totalBytes, byFolder, truncated];
}
