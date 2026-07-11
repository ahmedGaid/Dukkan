part of 'collections_bloc.dart';

sealed class CollectionsEvent extends Equatable {
  const CollectionsEvent();

  @override
  List<Object?> get props => [];
}

/// Subscribe to this shop's realtime collections (fired once on page open).
class CollectionsStarted extends CollectionsEvent {
  const CollectionsStarted();
}

class CollectionsRetryRequested extends CollectionsEvent {
  const CollectionsRetryRequested();
}

class CollectionsCreateRequested extends CollectionsEvent {
  const CollectionsCreateRequested({required this.nameAr, required this.nameEn});

  final String nameAr;
  final String nameEn;

  @override
  List<Object?> get props => [nameAr, nameEn];
}

class CollectionsRenameRequested extends CollectionsEvent {
  const CollectionsRenameRequested({
    required this.collectionId,
    required this.nameAr,
    required this.nameEn,
  });

  final String collectionId;
  final String nameAr;
  final String nameEn;

  @override
  List<Object?> get props => [collectionId, nameAr, nameEn];
}

class CollectionsDeleteRequested extends CollectionsEvent {
  const CollectionsDeleteRequested(this.collectionId);

  final String collectionId;

  @override
  List<Object?> get props => [collectionId];
}

/// Internal: a new snapshot arrived from the stream.
class _CollectionsUpdated extends CollectionsEvent {
  const _CollectionsUpdated(this.collections);

  final List<ShopCollection> collections;

  @override
  List<Object?> get props => [collections];
}

/// Internal: the watch stream errored.
class _CollectionsWatchFailed extends CollectionsEvent {
  const _CollectionsWatchFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}

/// Internal: a create/rename/delete call failed.
class _CollectionsActionFailed extends CollectionsEvent {
  const _CollectionsActionFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
