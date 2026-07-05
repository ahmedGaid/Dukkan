part of 'favorites_bloc.dart';

enum FavoritesStatus { loading, loaded, error }

class FavoritesState extends Equatable {
  const FavoritesState({
    this.status = FavoritesStatus.loading,
    this.favorites = const Favorites.empty(),
  });

  final FavoritesStatus status;
  final Favorites favorites;

  bool isShopFavorite(String shopId) => favorites.hasShop(shopId);
  bool isProductFavorite(String productId) => favorites.hasProduct(productId);

  FavoritesState copyWith({
    FavoritesStatus? status,
    Favorites? favorites,
  }) {
    return FavoritesState(
      status: status ?? this.status,
      favorites: favorites ?? this.favorites,
    );
  }

  @override
  List<Object?> get props => [status, favorites];
}
