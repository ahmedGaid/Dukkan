part of 'favorites_page_bloc.dart';

enum FavoritesPageStatus { loading, loaded, error }

class FavoritesPageState extends Equatable {
  const FavoritesPageState({
    this.status = FavoritesPageStatus.loading,
    this.favoriteShops = const [],
    this.favoriteProducts = const [],
    this.shopsById = const {},
  });

  final FavoritesPageStatus status;
  final List<Shop> favoriteShops;
  final List<Product> favoriteProducts;

  /// Every shop, keyed by id — supplies each favorite product's shop-name
  /// subtitle even when that shop itself isn't favorited.
  final Map<String, Shop> shopsById;

  bool get isEmpty => favoriteShops.isEmpty && favoriteProducts.isEmpty;

  FavoritesPageState copyWith({
    FavoritesPageStatus? status,
    List<Shop>? favoriteShops,
    List<Product>? favoriteProducts,
    Map<String, Shop>? shopsById,
  }) {
    return FavoritesPageState(
      status: status ?? this.status,
      favoriteShops: favoriteShops ?? this.favoriteShops,
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      shopsById: shopsById ?? this.shopsById,
    );
  }

  @override
  List<Object?> get props =>
      [status, favoriteShops, favoriteProducts, shopsById];
}
