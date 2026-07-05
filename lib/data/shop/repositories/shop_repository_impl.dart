import '../../../core/errors/failures.dart';
import '../../../core/network/network_info.dart';
import '../../../domain/shop/entities/shop.dart';
import '../../../domain/shop/repositories/shop_repository.dart';
import '../datasources/shop_local_datasource.dart';
import '../datasources/shop_remote_datasource.dart';
import '../models/shop_model.dart';

class ShopRepositoryImpl implements ShopRepository {
  ShopRepositoryImpl(this._remote, this._local, this._networkInfo);

  final ShopRemoteDataSource _remote;
  final ShopLocalDataSource _local;
  final NetworkInfo _networkInfo;

  @override
  Stream<List<Shop>> watchShops() async* {
    if (await _networkInfo.isConnected) {
      await for (final shops in _remote.watchShops()) {
        await _local.cacheShops(shops);
        yield shops;
      }
    } else {
      yield await _local.getCachedShops();
    }
  }

  @override
  Stream<Shop> watchShop(String shopId) async* {
    if (await _networkInfo.isConnected) {
      yield* _remote.watchShop(shopId);
    } else {
      final cached = await _local.getCachedShops();
      Shop? match;
      for (final shop in cached) {
        if (shop.id == shopId) {
          match = shop;
          break;
        }
      }
      if (match == null) {
        throw CacheFailure('Shop $shopId not cached');
      }
      yield match;
    }
  }

  @override
  Future<Shop?> getShopByOwner(String ownerUid) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkFailure('No connection');
    }
    return _remote.getShopByOwner(ownerUid);
  }

  @override
  Future<Shop> createShop({
    required String ownerUid,
    required String name,
    required String nameAr,
    required String address,
    String? logoUrl,
    bool isOpen = true,
    List<String> categories = const [],
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkFailure('No connection');
    }
    return _remote.createShop(ShopModel(
      id: '',
      ownerUid: ownerUid,
      name: name,
      nameAr: nameAr,
      logoUrl: logoUrl,
      address: address,
      isOpen: isOpen,
      categories: categories,
    ));
  }
}
