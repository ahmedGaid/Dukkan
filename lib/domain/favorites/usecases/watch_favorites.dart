import '../entities/favorites.dart';
import '../repositories/favorites_repository.dart';

class WatchFavorites {
  const WatchFavorites(this._repository);

  final FavoritesRepository _repository;

  Stream<Favorites> call(String uid) => _repository.watchFavorites(uid);
}
