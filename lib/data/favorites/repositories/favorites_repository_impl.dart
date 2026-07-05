import '../../../core/errors/failures.dart';
import '../../../core/network/network_info.dart';
import '../../../domain/favorites/entities/favorites.dart';
import '../../../domain/favorites/repositories/favorites_repository.dart';
import '../datasources/favorites_remote_datasource.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._remote, this._networkInfo);

  final FavoritesRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Stream<Favorites> watchFavorites(String uid) => _remote.watchFavorites(uid);

  @override
  Future<void> toggleFavoriteShop(String uid, String shopId) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkFailure('No connection');
    }
    await _remote.toggleFavoriteShop(uid, shopId);
  }

  @override
  Future<void> toggleFavoriteProduct(String uid, String productId) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkFailure('No connection');
    }
    await _remote.toggleFavoriteProduct(uid, productId);
  }
}
