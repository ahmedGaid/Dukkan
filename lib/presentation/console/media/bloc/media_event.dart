part of 'media_bloc.dart';

sealed class MediaEvent extends Equatable {
  const MediaEvent();

  @override
  List<Object?> get props => [];
}

class MediaStarted extends MediaEvent {
  const MediaStarted();
}

class MediaRetryRequested extends MediaEvent {
  const MediaRetryRequested();
}

/// null = الكل (no prefix filter).
class MediaFolderChanged extends MediaEvent {
  const MediaFolderChanged(this.folder);

  final String? folder;

  @override
  List<Object?> get props => [folder];
}

class MediaLoadMoreRequested extends MediaEvent {
  const MediaLoadMoreRequested();
}

class MediaSelectionToggled extends MediaEvent {
  const MediaSelectionToggled(this.key);

  final String key;

  @override
  List<Object?> get props => [key];
}

class MediaSelectionCleared extends MediaEvent {
  const MediaSelectionCleared();
}

class MediaDeleteSelectedRequested extends MediaEvent {
  const MediaDeleteSelectedRequested();
}

class MediaUploadRequested extends MediaEvent {
  const MediaUploadRequested({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;

  @override
  List<Object?> get props => [bytes, contentType];
}

/// Fired once, lazily, the first time either finder tab is opened — loads
/// the full key list + every doc reference and computes both diffs.
class MediaFindersRequested extends MediaEvent {
  const MediaFindersRequested();
}

class MediaOrphanSelectionToggled extends MediaEvent {
  const MediaOrphanSelectionToggled(this.key);

  final String key;

  @override
  List<Object?> get props => [key];
}

class MediaOrphanSelectAllRequested extends MediaEvent {
  const MediaOrphanSelectAllRequested();
}

class MediaOrphanSelectionCleared extends MediaEvent {
  const MediaOrphanSelectionCleared();
}

class MediaOrphanDeleteSelectedRequested extends MediaEvent {
  const MediaOrphanDeleteSelectedRequested();
}
