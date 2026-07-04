import '../entities/product.dart';

/// Product catalog boundary, scoped per shop. Same online/offline contract as
/// `ShopRepository`.
abstract class ProductRepository {
  Stream<List<Product>> watchProductsByShop(String shopId);

  /// Single product (product detail, C2) — throws [CacheFailure] if offline
  /// and not present in any cached shop's product list.
  Future<Product> getProduct(String productId);
}
