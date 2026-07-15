import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../domain/media/entities/media_object.dart';
import '../../../../domain/media/entities/media_reference.dart';
import '../../../../domain/media/entities/media_stats.dart';
import '../../../../domain/media/media_diff.dart';
import '../../../../domain/media/usecases/delete_media.dart';
import '../../../../domain/media/usecases/get_all_media.dart';
import '../../../../domain/media/usecases/get_media_references.dart';
import '../../../../domain/media/usecases/get_media_stats.dart';
import '../../../../domain/media/usecases/list_media.dart';
import '../../../../domain/storage/usecases/upload_image.dart';

part 'media_event.dart';
part 'media_state.dart';

/// Drives the console media library (`/console/media`, FC14): browse tab
/// (folder-filtered, cursor-paginated, multi-select bulk delete) + the two
/// finder tabs (unused / broken), loaded lazily on first visit since each
/// scans the whole bucket + every image-URL-holding collection.
class MediaBloc extends Bloc<MediaEvent, MediaState> {
  MediaBloc({
    required ListMedia listMedia,
    required GetAllMedia getAllMedia,
    required GetMediaStats getMediaStats,
    required DeleteMedia deleteMedia,
    required GetMediaReferences getMediaReferences,
    required UploadImage uploadImage,
  })  : _listMedia = listMedia,
        _getAllMedia = getAllMedia,
        _getMediaStats = getMediaStats,
        _deleteMedia = deleteMedia,
        _getMediaReferences = getMediaReferences,
        _uploadImage = uploadImage,
        super(const MediaState()) {
    on<MediaStarted>(_onStarted);
    on<MediaRetryRequested>(_onStarted);
    on<MediaFolderChanged>(_onFolderChanged);
    on<MediaLoadMoreRequested>(_onLoadMore);
    on<MediaSelectionToggled>(_onSelectionToggled);
    on<MediaSelectionCleared>((_, emit) => emit(state.copyWith(selectedKeys: const {})));
    on<MediaDeleteSelectedRequested>(_onDeleteSelected);
    on<MediaUploadRequested>(_onUpload);
    on<MediaFindersRequested>(_onFindersRequested);
    on<MediaOrphanSelectionToggled>(_onOrphanSelectionToggled);
    on<MediaOrphanSelectAllRequested>(_onOrphanSelectAll);
    on<MediaOrphanSelectionCleared>(
      (_, emit) => emit(state.copyWith(orphanSelectedKeys: const {})),
    );
    on<MediaOrphanDeleteSelectedRequested>(_onOrphanDeleteSelected);

    add(const MediaStarted());
  }

  final ListMedia _listMedia;
  final GetAllMedia _getAllMedia;
  final GetMediaStats _getMediaStats;
  final DeleteMedia _deleteMedia;
  final GetMediaReferences _getMediaReferences;
  final UploadImage _uploadImage;

  Future<void> _onStarted(MediaEvent event, Emitter<MediaState> emit) async {
    emit(state.copyWith(status: MediaStatus.loading));
    try {
      final pageFuture = _listMedia(folder: state.folder);
      final statsFuture = _getMediaStats();
      final page = await pageFuture;
      final stats = await statsFuture;
      emit(state.copyWith(
        status: MediaStatus.loaded,
        objects: page.objects,
        cursor: page.cursor,
        stats: stats,
        selectedKeys: const {},
      ));
    } catch (_) {
      emit(state.copyWith(status: MediaStatus.error));
    }
  }

  Future<void> _onFolderChanged(MediaFolderChanged event, Emitter<MediaState> emit) async {
    if (event.folder == state.folder) return;
    emit(state.copyWith(
      folder: event.folder,
      status: MediaStatus.loading,
      objects: const [],
      cursor: null,
      selectedKeys: const {},
    ));
    try {
      final page = await _listMedia(folder: event.folder);
      emit(state.copyWith(
        status: MediaStatus.loaded,
        objects: page.objects,
        cursor: page.cursor,
      ));
    } catch (_) {
      emit(state.copyWith(status: MediaStatus.error));
    }
  }

  Future<void> _onLoadMore(MediaLoadMoreRequested event, Emitter<MediaState> emit) async {
    if (state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _listMedia(folder: state.folder, cursor: state.cursor);
      emit(state.copyWith(
        objects: [...state.objects, ...page.objects],
        cursor: page.cursor,
        loadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(loadingMore: false));
    }
  }

  void _onSelectionToggled(MediaSelectionToggled event, Emitter<MediaState> emit) {
    final next = {...state.selectedKeys};
    if (!next.remove(event.key)) next.add(event.key);
    emit(state.copyWith(selectedKeys: next));
  }

  Future<void> _onDeleteSelected(
    MediaDeleteSelectedRequested event,
    Emitter<MediaState> emit,
  ) async {
    final keys = state.selectedKeys;
    if (keys.isEmpty || state.deleteBusy) return;
    emit(state.copyWith(deleteBusy: true));
    try {
      await _deleteMedia(keys.toList());
      // Optimistic in-place update (Shoppy lesson) — no refetch/Loading flicker.
      emit(state.copyWith(
        objects: state.objects.where((o) => !keys.contains(o.key)).toList(growable: false),
        selectedKeys: const {},
        deleteBusy: false,
      ));
      unawaited(_refreshStats(emit));
    } catch (_) {
      emit(state.copyWith(deleteBusy: false));
    }
  }

  Future<void> _refreshStats(Emitter<MediaState> emit) async {
    try {
      final stats = await _getMediaStats();
      if (!emit.isDone) emit(state.copyWith(stats: stats));
    } catch (_) {
      // Best-effort — the previous totals just stay on screen.
    }
  }

  Future<void> _onUpload(MediaUploadRequested event, Emitter<MediaState> emit) async {
    final folder = state.folder;
    if (folder == null || state.uploadBusy) return;
    emit(state.copyWith(uploadBusy: true, uploadError: null));
    try {
      final url = await _uploadImage(
        bytes: event.bytes,
        contentType: event.contentType,
        folder: folder,
      );
      final base = AppConfig.mediaPublicBaseUrl.replaceFirst(RegExp(r'/$'), '');
      final key = url.startsWith('$base/') ? url.substring(base.length + 1) : url;
      final uploaded = MediaObject(
        key: key,
        size: event.bytes.length,
        uploaded: DateTime.now(),
        url: url,
      );
      emit(state.copyWith(objects: [uploaded, ...state.objects], uploadBusy: false));
      unawaited(_refreshStats(emit));
    } catch (e) {
      emit(state.copyWith(uploadBusy: false, uploadError: e.toString()));
    }
  }

  Future<void> _onFindersRequested(
    MediaFindersRequested event,
    Emitter<MediaState> emit,
  ) async {
    if (state.findersStatus == MediaFindersStatus.loading ||
        state.findersStatus == MediaFindersStatus.loaded) {
      return;
    }
    emit(state.copyWith(findersStatus: MediaFindersStatus.loading));
    try {
      final allFuture = _getAllMedia();
      final refsFuture = _getMediaReferences();
      final all = await allFuture;
      final refs = await refsFuture;
      emit(state.copyWith(
        findersStatus: MediaFindersStatus.loaded,
        orphans: findOrphanMedia(all, refs),
        broken: findBrokenReferences(refs, all),
      ));
    } catch (_) {
      emit(state.copyWith(findersStatus: MediaFindersStatus.error));
    }
  }

  void _onOrphanSelectionToggled(
    MediaOrphanSelectionToggled event,
    Emitter<MediaState> emit,
  ) {
    final next = {...state.orphanSelectedKeys};
    if (!next.remove(event.key)) next.add(event.key);
    emit(state.copyWith(orphanSelectedKeys: next));
  }

  void _onOrphanSelectAll(MediaOrphanSelectAllRequested event, Emitter<MediaState> emit) {
    emit(state.copyWith(orphanSelectedKeys: state.orphans.map((o) => o.key).toSet()));
  }

  Future<void> _onOrphanDeleteSelected(
    MediaOrphanDeleteSelectedRequested event,
    Emitter<MediaState> emit,
  ) async {
    final keys = state.orphanSelectedKeys;
    if (keys.isEmpty || state.findersDeleteBusy) return;
    emit(state.copyWith(findersDeleteBusy: true));
    try {
      await _deleteMedia(keys.toList());
      emit(state.copyWith(
        orphans: state.orphans.where((o) => !keys.contains(o.key)).toList(growable: false),
        objects: state.objects.where((o) => !keys.contains(o.key)).toList(growable: false),
        orphanSelectedKeys: const {},
        findersDeleteBusy: false,
      ));
      unawaited(_refreshStats(emit));
    } catch (_) {
      emit(state.copyWith(findersDeleteBusy: false));
    }
  }
}
