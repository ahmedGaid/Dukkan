import '../../../core/errors/failures.dart';
import '../../../core/network/network_info.dart';
import '../../../domain/product/entities/product.dart';
import '../../../domain/product/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remote, this._local, this._networkInfo);

  final ProductRemoteDataSource _remote;
  final ProductLocalDataSource _local;
  final NetworkInfo _networkInfo;

  @override
  Stream<List<Product>> watchProductsByShop(String shopId) async* {
    if (await _networkInfo.isConnected) {
      await for (final products in _remote.watchProductsByShop(shopId)) {
        await _local.cacheProductsByShop(shopId, products);
        yield products;
      }
    } else {
      yield await _local.getCachedProductsByShop(shopId);
    }
  }

  @override
  Future<Product> getProduct(String productId) async {
    if (await _networkInfo.isConnected) {
      return _remote.getProduct(productId);
    }
    final cached = await _local.getCachedProduct(productId);
    if (cached == null) {
      throw CacheFailure('Product $productId not cached');
    }
    return cached;
  }
}
