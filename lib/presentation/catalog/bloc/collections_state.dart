part of 'collections_bloc.dart';

enum CollectionsStatus { loading, loaded, error }

/// Status of the in-flight create/rename/delete call — separate from
/// [CollectionsStatus] so a mutation never re-triggers the page's own
/// Loading state. Success needs no local flag: the new list arrives through
/// the same watch stream (matches `OrderDetailBloc`'s cancel/rate pattern).
enum CollectionsActionStatus { idle, submitting, failure }

class CollectionsState extends Equatable {
  const CollectionsState({
    this.status = CollectionsStatus.loading,
    this.collections = const [],
    this.actionStatus = CollectionsActionStatus.idle,
  });

  final CollectionsStatus status;
  final List<ShopCollection> collections;
  final CollectionsActionStatus actionStatus;

  CollectionsState copyWith({
    CollectionsStatus? status,
    List<ShopCollection>? collections,
    CollectionsActionStatus? actionStatus,
  }) {
    return CollectionsState(
      status: status ?? this.status,
      collections: collections ?? this.collections,
      actionStatus: actionStatus ?? this.actionStatus,
    );
  }

  @override
  List<Object?> get props => [status, collections, actionStatus];
}
