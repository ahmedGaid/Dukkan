import 'package:equatable/equatable.dart';

import 'media_object.dart';

/// One cursor-paginated page of R2 objects, same shape as `AuditPage` /
/// `NotificationHistoryPage`.
class MediaPage extends Equatable {
  const MediaPage({required this.objects, required this.cursor});

  final List<MediaObject> objects;

  /// Pass back as `cursor` to fetch the next page; null means no more pages.
  final String? cursor;

  bool get hasMore => cursor != null;

  @override
  List<Object?> get props => [objects, cursor];
}
