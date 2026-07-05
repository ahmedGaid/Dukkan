import '../entities/favorites.dart';

/// Favorites boundary. Reads go straight to Firestore's own (SDK-level)
/// offline cache — no app-level local datasource, unlike Shop/Product, since
/// this is a low-stakes toggle rather than a primary browse feed. Writes
/// require connectivity, same contract as `createShop`/`createProduct`.
abstract class FavoritesRepository {
  Stream<Favorites> watchFavorites(String uid);

  Future<void> toggleFavoriteShop(String uid, String shopId);

  Future<void> toggleFavoriteProduct(String uid, String productId);
}
