import '../../../core/errors/failures.dart';
import '../../../core/network/network_info.dart';
import '../../../domain/collections/entities/shop_collection.dart';
import '../../../domain/collections/repositories/collections_repository.dart';
import '../datasources/collections_remote_datasource.dart';

class CollectionsRepositoryImpl implements CollectionsRepository {
  CollectionsRepositoryImpl(this._remote, this._networkInfo);

  final CollectionsRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Stream<List<ShopCollection>> watchCollections(String shopId) =>
      _remote.watchCollections(shopId);

  @override
  Future<List<ShopCollection>> getCollections(String shopId) =>
      _remote.getCollections(shopId);

  @override
  Future<ShopCollection> createCollection(
    String shopId, {
    required String nameAr,
    required String nameEn,
    required int sort,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkFailure('No connection');
    }
    return _remote.createCollection(
      shopId,
      nameAr: nameAr,
      nameEn: nameEn,
      sort: sort,
    );
  }

  @override
  Future<void> renameCollection(
    String shopId,
    String collectionId, {
    required String nameAr,
    required String nameEn,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkFailure('No connection');
    }
    await _remote.renameCollection(
      shopId,
      collectionId,
      nameAr: nameAr,
      nameEn: nameEn,
    );
  }

  @override
  Future<void> deleteCollection(String shopId, String collectionId) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkFailure('No connection');
    }
    await _remote.deleteCollection(shopId, collectionId);
  }
}
