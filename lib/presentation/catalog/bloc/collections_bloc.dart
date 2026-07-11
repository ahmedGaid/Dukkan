import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/collections/entities/shop_collection.dart';
import '../../../domain/collections/usecases/create_collection.dart';
import '../../../domain/collections/usecases/delete_collection.dart';
import '../../../domain/collections/usecases/rename_collection.dart';
import '../../../domain/collections/usecases/watch_collections.dart';

part 'collections_event.dart';
part 'collections_state.dart';

/// Drives the owner's collections manager (M6) — the shop id is the factory
/// param (mirrors `ProductsBloc`). Create/rename/delete are one-shot calls;
/// the sheet/dialog that triggers them closes optimistically (matches
/// `OrderDetailPage`'s cancel flow) — a failure surfaces once through
/// [CollectionsActionStatus.failure] for the page to snackbar.
class CollectionsBloc extends Bloc<CollectionsEvent, CollectionsState> {
  CollectionsBloc({
    required String shopId,
    required WatchCollections watchCollections,
    required CreateCollection createCollection,
    required RenameCollection renameCollection,
    required DeleteCollection deleteCollection,
  })  : _shopId = shopId,
        _watchCollections = watchCollections,
        _createCollection = createCollection,
        _renameCollection = renameCollection,
        _deleteCollection = deleteCollection,
        super(const CollectionsState()) {
    on<CollectionsStarted>(_onStarted);
    on<CollectionsRetryRequested>(_onStarted);
    on<CollectionsCreateRequested>(_onCreateRequested);
    on<CollectionsRenameRequested>(_onRenameRequested);
    on<CollectionsDeleteRequested>(_onDeleteRequested);
    on<_CollectionsUpdated>(_onUpdated);
    on<_CollectionsWatchFailed>(_onWatchFailed);
    on<_CollectionsActionFailed>(_onActionFailed);
  }

  final String _shopId;
  final WatchCollections _watchCollections;
  final CreateCollection _createCollection;
  final RenameCollection _renameCollection;
  final DeleteCollection _deleteCollection;
  StreamSubscription<List<ShopCollection>>? _sub;

  Future<void> _onStarted(
    CollectionsEvent event,
    Emitter<CollectionsState> emit,
  ) async {
    emit(state.copyWith(status: CollectionsStatus.loading));
    await _sub?.cancel();
    _sub = _watchCollections(_shopId).listen(
      (collections) => add(_CollectionsUpdated(collections)),
      onError: (Object error) => add(_CollectionsWatchFailed(error)),
    );
  }

  void _onUpdated(_CollectionsUpdated event, Emitter<CollectionsState> emit) {
    emit(state.copyWith(
      status: CollectionsStatus.loaded,
      collections: event.collections,
    ));
  }

  void _onWatchFailed(
    _CollectionsWatchFailed event,
    Emitter<CollectionsState> emit,
  ) {
    emit(state.copyWith(status: CollectionsStatus.error));
  }

  Future<void> _onCreateRequested(
    CollectionsCreateRequested event,
    Emitter<CollectionsState> emit,
  ) async {
    emit(state.copyWith(actionStatus: CollectionsActionStatus.submitting));
    try {
      await _createCollection(
        _shopId,
        nameAr: event.nameAr,
        nameEn: event.nameEn,
        sort: state.collections.length,
      );
    } catch (error) {
      add(_CollectionsActionFailed(error));
    }
  }

  Future<void> _onRenameRequested(
    CollectionsRenameRequested event,
    Emitter<CollectionsState> emit,
  ) async {
    emit(state.copyWith(actionStatus: CollectionsActionStatus.submitting));
    try {
      await _renameCollection(
        _shopId,
        event.collectionId,
        nameAr: event.nameAr,
        nameEn: event.nameEn,
      );
    } catch (error) {
      add(_CollectionsActionFailed(error));
    }
  }

  Future<void> _onDeleteRequested(
    CollectionsDeleteRequested event,
    Emitter<CollectionsState> emit,
  ) async {
    emit(state.copyWith(actionStatus: CollectionsActionStatus.submitting));
    try {
      await _deleteCollection(_shopId, event.collectionId);
    } catch (error) {
      add(_CollectionsActionFailed(error));
    }
  }

  void _onActionFailed(
    _CollectionsActionFailed event,
    Emitter<CollectionsState> emit,
  ) {
    emit(state.copyWith(actionStatus: CollectionsActionStatus.failure));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
