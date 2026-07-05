import '../repositories/favorites_repository.dart';

class ToggleFavoriteProduct {
  const ToggleFavoriteProduct(this._repository);

  final FavoritesRepository _repository;

  Future<void> call(String uid, String productId) =>
      _repository.toggleFavoriteProduct(uid, productId);
}
