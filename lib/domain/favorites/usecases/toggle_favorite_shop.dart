import '../repositories/favorites_repository.dart';

class ToggleFavoriteShop {
  const ToggleFavoriteShop(this._repository);

  final FavoritesRepository _repository;

  Future<void> call(String uid, String shopId) =>
      _repository.toggleFavoriteShop(uid, shopId);
}
