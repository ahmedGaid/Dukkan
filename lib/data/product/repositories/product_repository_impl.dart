import '../../../core/errors/failures.dart';
import '../../../core/network/network_info.dart';
import '../../../domain/product/entities/product.dart';
import '../../../domain/product/entities/stock_status.dart';
import '../../../domain/product/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

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
  Stream<List<Product>> watchAllProducts() async* {
    if (await _networkInfo.isConnected) {
      await for (final products in _remote.watchAllProducts()) {
        await _local.cacheAllProducts(products);
        yield products;
      }
    } else {
      yield await _local.getCachedAllProducts();
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

  @override
  Future<Product> createProduct({
    required String shopId,
    required String name,
    required String nameAr,
    required int priceMinor,
    required String category,
    required StockStatus stockStatus,
    required bool isPromo,
    String? imageUrl,
    String? subcategoryId,
    List<String> collectionIds = const [],
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkFailure('No connection');
    }
    return _remote.createProduct(ProductModel(
      id: '',
      shopId: shopId,
      name: name,
      nameAr: nameAr,
      priceMinor: priceMinor,
      category: category,
      stockStatus: stockStatus,
      isPromo: isPromo,
      imageUrl: imageUrl,
      subcategoryId: subcategoryId,
      collectionIds: collectionIds,
    ));
  }

  @override
  Future<void> updateProduct(Product product) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkFailure('No connection');
    }
    await _remote.updateProduct(ProductModel(
      id: product.id,
      shopId: product.shopId,
      name: product.name,
      nameAr: product.nameAr,
      priceMinor: product.priceMinor,
      category: product.category,
      stockStatus: product.stockStatus,
      isPromo: product.isPromo,
      imageUrl: product.imageUrl,
      subcategoryId: product.subcategoryId,
      collectionIds: product.collectionIds,
    ));
  }

  @override
  Future<void> deleteProduct(String productId) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkFailure('No connection');
    }
    await _remote.deleteProduct(productId);
  }
}
