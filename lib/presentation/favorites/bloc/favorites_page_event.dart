part of 'favorites_page_bloc.dart';

sealed class FavoritesPageEvent extends Equatable {
  const FavoritesPageEvent();

  @override
  List<Object?> get props => [];
}

/// Subscribe to the three feeds (fired once on Favorites tab open).
class FavoritesPageStarted extends FavoritesPageEvent {
  const FavoritesPageStarted();
}

/// Re-subscribe after an error (retry action).
class FavoritesPageRetryRequested extends FavoritesPageEvent {
  const FavoritesPageRetryRequested();
}

class _FavoriteIdsArrived extends FavoritesPageEvent {
  const _FavoriteIdsArrived(this.favorites);

  final Favorites favorites;

  @override
  List<Object?> get props => [favorites];
}

class _ShopsArrived extends FavoritesPageEvent {
  const _ShopsArrived(this.shops);

  final List<Shop> shops;

  @override
  List<Object?> get props => [shops];
}

class _ProductsArrived extends FavoritesPageEvent {
  const _ProductsArrived(this.products);

  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

class _FavoritesPageFailed extends FavoritesPageEvent {
  const _FavoritesPageFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
