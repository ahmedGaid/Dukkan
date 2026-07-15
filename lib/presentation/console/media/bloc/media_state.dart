part of 'media_bloc.dart';

enum MediaStatus { loading, loaded, error }

enum MediaFindersStatus { idle, loading, loaded, error }

class MediaState extends Equatable {
  const MediaState({
    this.status = MediaStatus.loading,
    this.folder,
    this.objects = const [],
    this.cursor,
    this.loadingMore = false,
    this.stats,
    this.selectedKeys = const {},
    this.deleteBusy = false,
    this.uploadBusy = false,
    this.uploadError,
    this.findersStatus = MediaFindersStatus.idle,
    this.orphans = const [],
    this.broken = const [],
    this.orphanSelectedKeys = const {},
    this.findersDeleteBusy = false,
  });

  final MediaStatus status;
  final String? folder; // null = الكل
  final List<MediaObject> objects;
  final String? cursor;
  final bool loadingMore;
  final MediaStats? stats;
  final Set<String> selectedKeys;
  final bool deleteBusy;
  final bool uploadBusy;
  final String? uploadError;

  final MediaFindersStatus findersStatus;
  final List<MediaObject> orphans;
  final List<MediaReference> broken;
  final Set<String> orphanSelectedKeys;
  final bool findersDeleteBusy;

  bool get hasMore => cursor != null;

  static const _unset = Object();

  MediaState copyWith({
    MediaStatus? status,
    Object? folder = _unset,
    List<MediaObject>? objects,
    Object? cursor = _unset,
    bool? loadingMore,
    Object? stats = _unset,
    Set<String>? selectedKeys,
    bool? deleteBusy,
    bool? uploadBusy,
    Object? uploadError = _unset,
    MediaFindersStatus? findersStatus,
    List<MediaObject>? orphans,
    List<MediaReference>? broken,
    Set<String>? orphanSelectedKeys,
    bool? findersDeleteBusy,
  }) {
    return MediaState(
      status: status ?? this.status,
      folder: folder == _unset ? this.folder : folder as String?,
      objects: objects ?? this.objects,
      cursor: cursor == _unset ? this.cursor : cursor as String?,
      loadingMore: loadingMore ?? this.loadingMore,
      stats: stats == _unset ? this.stats : stats as MediaStats?,
      selectedKeys: selectedKeys ?? this.selectedKeys,
      deleteBusy: deleteBusy ?? this.deleteBusy,
      uploadBusy: uploadBusy ?? this.uploadBusy,
      uploadError: uploadError == _unset ? this.uploadError : uploadError as String?,
      findersStatus: findersStatus ?? this.findersStatus,
      orphans: orphans ?? this.orphans,
      broken: broken ?? this.broken,
      orphanSelectedKeys: orphanSelectedKeys ?? this.orphanSelectedKeys,
      findersDeleteBusy: findersDeleteBusy ?? this.findersDeleteBusy,
    );
  }

  @override
  List<Object?> get props => [
        status,
        folder,
        objects,
        cursor,
        loadingMore,
        stats,
        selectedKeys,
        deleteBusy,
        uploadBusy,
        uploadError,
        findersStatus,
        orphans,
        broken,
        orphanSelectedKeys,
        findersDeleteBusy,
      ];
}
