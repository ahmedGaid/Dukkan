part of 'favorites_bloc.dart';

sealed class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

/// Internal: the signed-in uid changed (login/logout/account switch).
class _FavoritesAuthChanged extends FavoritesEvent {
  const _FavoritesAuthChanged(this.uid);

  final String? uid;

  @override
  List<Object?> get props => [uid];
}

/// Internal: a new snapshot arrived from the watch stream.
class _FavoritesUpdated extends FavoritesEvent {
  const _FavoritesUpdated(this.favorites);

  final Favorites favorites;

  @override
  List<Object?> get props => [favorites];
}

/// Internal: the stream errored.
class _FavoritesFailed extends FavoritesEvent {
  const _FavoritesFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
